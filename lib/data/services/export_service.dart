import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import 'package:printing/printing.dart' as printing;
import 'package:image/image.dart' as img;
import '../../domain/models/model.dart';
// math moved to utils in rot
import '../../utils/rotation_utils.dart' as rot;

// NOTE:
// - This exporter uses a raster snapshot of the UI (RepaintBoundary) and embeds it into a new PDF.
// - It does NOT perform vector-accurate stamping into the source PDF.
// - Vector stamping remains unimplemented with FOSS-only constraints because the `pdf` package
//   cannot import/modify existing PDF pages. If/when a suitable FOSS library exists, wire it here.

class ExportService {
  /// Compose a new PDF from source PDF bytes; returns the resulting PDF bytes.
  Future<Uint8List?> exportSignedPdfFromBytes({
    required Uint8List srcBytes,
    required Size uiPageSize,
    required Uint8List? signatureImageBytes,
    Map<int, List<SignaturePlacement>>? placementsByPage,
    Map<String, Uint8List>? libraryBytes,
    double targetDpi = 144.0,
  }) async {
    // Per-call caches to avoid redundant decode/encode and image embedding work
    final Map<String, Uint8List> _processedBytesCache = <String, Uint8List>{};
    final Map<String, pw.MemoryImage> _memoryImageCache =
        <String, pw.MemoryImage>{};
    final Map<String, double> _aspectRatioCache = <String, double>{};

    // Returns a stable-ish cache key for bytes within this process (not content-hash, but good enough per-call)
    String _baseKeyForBytes(Uint8List b) =>
        '${identityHashCode(b)}:${b.length}';

    // Fast PNG signature check (no string allocation)
    bool _isPng(Uint8List bytes) {
      if (bytes.length < 8) return false;
      return bytes[0] == 0x89 &&
          bytes[1] == 0x50 && // P
          bytes[2] == 0x4E && // N
          bytes[3] == 0x47 && // G
          bytes[4] == 0x0D &&
          bytes[5] == 0x0A &&
          bytes[6] == 0x1A &&
          bytes[7] == 0x0A;
    }

    // Resolve base (unprocessed) bytes for a placement, considering library override.
    Uint8List _getBaseBytes(SignaturePlacement placement) {
      Uint8List baseBytes = placement.asset.bytes;
      final libKey = placement.asset.name;
      if (libKey != null && libraryBytes != null) {
        final libBytes = libraryBytes[libKey];
        if (libBytes != null && libBytes.isNotEmpty) {
          baseBytes = libBytes;
        }
      }
      return baseBytes;
    }

    // Get processed bytes for a placement, with caching.
    Uint8List _getProcessedBytes(SignaturePlacement placement) {
      final Uint8List baseBytes = _getBaseBytes(placement);

      final adj = placement.graphicAdjust;
      final cacheKey =
          '${_baseKeyForBytes(baseBytes)}|c=${adj.contrast}|b=${adj.brightness}|bg=${adj.bgRemoval}';
      final cached = _processedBytesCache[cacheKey];
      if (cached != null) return cached;

      // If no graphic changes requested, return bytes as-is (conversion to PNG is deferred to MemoryImage step)
      final bool needsAdjust =
          (adj.contrast != 1.0 || adj.brightness != 1.0 || adj.bgRemoval);
      if (!needsAdjust) {
        _processedBytesCache[cacheKey] = baseBytes;
        return baseBytes;
      }

      try {
        final decoded = img.decodeImage(baseBytes);
        if (decoded == null) {
          _processedBytesCache[cacheKey] = baseBytes;
          return baseBytes;
        }
        img.Image processed = decoded;

        if (adj.contrast != 1.0 || adj.brightness != 1.0) {
          processed = img.adjustColor(
            processed,
            contrast: adj.contrast,
            brightness: adj.brightness,
          );
        }

        if (adj.bgRemoval) {
          processed = _removeBackground(processed);
        }

        final outBytes = Uint8List.fromList(img.encodePng(processed));
        _processedBytesCache[cacheKey] = outBytes;
        return outBytes;
      } catch (_) {
        // If processing fails, fall back to original
        _processedBytesCache[cacheKey] = baseBytes;
        return baseBytes;
      }
    }

    // Wrap bytes in a pw.MemoryImage with caching, converting to PNG only when necessary.
    pw.MemoryImage? _getMemoryImage(Uint8List bytes) {
      final key = _baseKeyForBytes(bytes);
      final cached = _memoryImageCache[key];
      if (cached != null) return cached;
      try {
        if (_isPng(bytes)) {
          final imgObj = pw.MemoryImage(bytes);
          _memoryImageCache[key] = imgObj;
          return imgObj;
        }
        // Convert to PNG to preserve transparency if not already PNG
        final decoded = img.decodeImage(bytes);
        if (decoded == null) return null;
        final png = Uint8List.fromList(img.encodePng(decoded, level: 6));
        final imgObj = pw.MemoryImage(png);
        _memoryImageCache[key] = imgObj;
        return imgObj;
      } catch (_) {
        return null;
      }
    }

    // Compute and cache aspect ratio (width/height) for given bytes
    double? _getAspectRatioFromBytes(Uint8List bytes) {
      final key = _baseKeyForBytes(bytes);
      final c = _aspectRatioCache[key];
      if (c != null) return c;
      try {
        final decoded = img.decodeImage(bytes);
        if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
          return null;
        }
        final ar = decoded.width / decoded.height;
        _aspectRatioCache[key] = ar;
        return ar;
      } catch (_) {
        return null;
      }
    }

    final out = pw.Document(version: pdf.PdfVersion.pdf_1_4, compress: false);
    int pageIndex = 0;
    bool anyPage = false;
    try {
      await for (final raster in printing.Printing.raster(
        srcBytes,
        dpi: targetDpi,
      )) {
        anyPage = true;
        pageIndex++;
        final widthPx = raster.width;
        final heightPx = raster.height;
        final widthPts = widthPx * 72.0 / targetDpi;
        final heightPts = heightPx * 72.0 / targetDpi;

        final bgPng = await raster.toPng();
        final bgImg = pw.MemoryImage(bgPng);

        final hasMulti =
            (placementsByPage != null && placementsByPage.isNotEmpty);
        final pagePlacements =
            hasMulti
                ? (placementsByPage[pageIndex] ?? const <SignaturePlacement>[])
                : const <SignaturePlacement>[];

        out.addPage(
          pw.Page(
            pageTheme: pw.PageTheme(
              margin: pw.EdgeInsets.zero,
              pageFormat: pdf.PdfPageFormat(widthPts, heightPts),
            ),
            build: (ctx) {
              final children = <pw.Widget>[
                pw.Positioned(
                  left: 0,
                  top: 0,
                  child: pw.Image(
                    bgImg,
                    width: widthPts,
                    height: heightPts,
                    fit: pw.BoxFit.fill,
                  ),
                ),
              ];
              // Multi-placement stamping: per-placement image from libraryBytes
              if (hasMulti && pagePlacements.isNotEmpty) {
                for (var i = 0; i < pagePlacements.length; i++) {
                  final placement = pagePlacements[i];
                  final r = placement.rect;
                  // rect is stored in normalized units (0..1) relative to page
                  final left = r.left * widthPts;
                  final top = r.top * heightPts;
                  final w = r.width * widthPts;
                  final h = r.height * heightPts;

                  // Get processed bytes (cached) and then embed as MemoryImage (cached)
                  Uint8List bytes = _getProcessedBytes(placement);
                  if (bytes.isEmpty && signatureImageBytes != null) {
                    bytes = signatureImageBytes;
                  }

                  if (bytes.isNotEmpty) {
                    final imgObj = _getMemoryImage(bytes);
                    if (imgObj != null) {
                      // Align with RotatedSignatureImage: counterclockwise positive
                      final angle = rot.radians(placement.rotationDeg);
                      // Prefer AR from base bytes to avoid extra decode of processed
                      final baseBytes = _getBaseBytes(placement);
                      final ar = _getAspectRatioFromBytes(baseBytes);
                      final scaleToFit = rot.scaleToFitForAngle(angle, ar: ar);

                      children.add(
                        pw.Positioned(
                          left: left,
                          top: top,
                          child: pw.SizedBox(
                            width: w,
                            height: h,
                            child: pw.FittedBox(
                              fit: pw.BoxFit.contain,
                              child: pw.Transform.scale(
                                scale: scaleToFit,
                                child: pw.Transform.rotate(
                                  angle: angle,
                                  child: pw.Image(imgObj),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  }
                }
              }
              return pw.Stack(children: children);
            },
          ),
        );
      }
    } catch (e) {
      anyPage = false;
    }

    if (!anyPage) {
      // Fallback as A4 blank page with optional signature
      final widthPts = pdf.PdfPageFormat.a4.width;
      final heightPts = pdf.PdfPageFormat.a4.height;

      final hasMulti =
          (placementsByPage != null && placementsByPage.isNotEmpty);
      final pagePlacements =
          hasMulti
              ? (placementsByPage[1] ?? const <SignaturePlacement>[])
              : const <SignaturePlacement>[];

      out.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            margin: pw.EdgeInsets.zero,
            pageFormat: pdf.PdfPageFormat(widthPts, heightPts),
          ),
          build: (ctx) {
            final children = <pw.Widget>[
              pw.Container(
                width: widthPts,
                height: heightPts,
                color: pdf.PdfColors.white,
              ),
            ];

            if (hasMulti && pagePlacements.isNotEmpty) {
              for (var i = 0; i < pagePlacements.length; i++) {
                final placement = pagePlacements[i];
                final r = placement.rect;
                // rect is stored in normalized units (0..1) relative to page
                final left = r.left * widthPts;
                final top = r.top * heightPts;
                final w = r.width * widthPts;
                final h = r.height * heightPts;

                Uint8List bytes = _getProcessedBytes(placement);
                if (bytes.isEmpty && signatureImageBytes != null) {
                  bytes = signatureImageBytes;
                }

                if (bytes.isNotEmpty) {
                  final imgObj = _getMemoryImage(bytes);
                  if (imgObj != null) {
                    final angle = rot.radians(placement.rotationDeg);
                    final baseBytes = _getBaseBytes(placement);
                    final ar = _getAspectRatioFromBytes(baseBytes);
                    final scaleToFit = rot.scaleToFitForAngle(angle, ar: ar);

                    children.add(
                      pw.Positioned(
                        left: left,
                        top: top,
                        child: pw.SizedBox(
                          width: w,
                          height: h,
                          child: pw.FittedBox(
                            fit: pw.BoxFit.contain,
                            child: pw.Transform.scale(
                              scale: scaleToFit,
                              child: pw.Transform.rotate(
                                angle: angle,
                                child: pw.Image(imgObj),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                }
              }
            }
            return pw.Stack(children: children);
          },
        ),
      );
    }

    try {
      return await out.save();
    } catch (_) {
      return null;
    }
  }

  /// Helper: write bytes returned from [exportSignedPdfFromBytes] to a file path.
  Future<bool> saveBytesToFile({
    required Uint8List bytes,
    required String outputPath,
  }) async {
    try {
      final file = File(outputPath);
      await file.writeAsBytes(bytes, flush: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Remove near-white background by making pixels with high brightness transparent
  img.Image _removeBackground(img.Image image) {
    final result =
        image.hasAlpha ? img.Image.from(image) : image.convert(numChannels: 4);

    const int threshold = 245; // Near-white threshold (0-255)

    for (int y = 0; y < result.height; y++) {
      for (int x = 0; x < result.width; x++) {
        final pixel = result.getPixel(x, y);

        // Get RGB values
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;

        // Check if pixel is near-white (all channels above threshold)
        if (r >= threshold && g >= threshold && b >= threshold) {
          // Make transparent
          result.setPixelRgba(x, y, r, g, b, 0);
        }
      }
    }

    return result;
  }
}
