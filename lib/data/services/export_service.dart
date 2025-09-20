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
import '../../utils/background_removal.dart' as br;

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
    Map<String, img.Image>? libraryImages,
    double targetDpi = 144.0,
  }) async {
    // Per-call caches to avoid redundant decode/encode and image embedding work
    final Map<String, img.Image> _baseImageCache = <String, img.Image>{};
    final Map<String, img.Image> _processedImageCache = <String, img.Image>{};
    final Map<String, Uint8List> _encodedPngCache = <String, Uint8List>{};
    final Map<String, pw.MemoryImage> _memoryImageCache =
        <String, pw.MemoryImage>{};
    final Map<String, double> _aspectRatioCache = <String, double>{};

    // Returns a stable-ish cache key for bytes within this process (not content-hash, but good enough per-call)
    String _baseKeyForImage(img.Image im) =>
        'im:${identityHashCode(im)}:${im.width}x${im.height}';
    String _adjustKey(GraphicAdjust adj) =>
        'c=${adj.contrast}|b=${adj.brightness}|bg=${adj.bgRemoval}';

    // Removed: PNG signature helper is no longer needed; we always encode to PNG explicitly.

    // Resolve base (unprocessed) image for a placement, considering library override.
    img.Image _getBaseImage(SignaturePlacement placement) {
      final libKey = placement.asset.name;
      if (libKey != null && libraryImages != null) {
        final cached = _baseImageCache[libKey];
        if (cached != null) return cached;
        final provided = libraryImages[libKey];
        if (provided != null) {
          _baseImageCache[libKey] = provided;
          return provided;
        }
      }
      return placement.asset.sigImage;
    }

    // Get processed image for a placement, with caching.
    img.Image _getProcessedImage(SignaturePlacement placement) {
      final base = _getBaseImage(placement);
      final key =
          '${_baseKeyForImage(base)}|${_adjustKey(placement.graphicAdjust)}';
      final cached = _processedImageCache[key];
      if (cached != null) return cached;
      final adj = placement.graphicAdjust;
      img.Image processed = base;
      if (adj.contrast != 1.0 || adj.brightness != 1.0) {
        processed = img.adjustColor(
          processed,
          contrast: adj.contrast,
          brightness: adj.brightness,
        );
      }
      if (adj.bgRemoval) {
        processed = br.removeNearWhiteBackground(processed, threshold: 240);
      }
      _processedImageCache[key] = processed;
      return processed;
    }

    // Get PNG bytes for the processed image, caching the encoding.
    Uint8List _getProcessedPng(SignaturePlacement placement) {
      final base = _getBaseImage(placement);
      final key =
          '${_baseKeyForImage(base)}|${_adjustKey(placement.graphicAdjust)}';
      final cached = _encodedPngCache[key];
      if (cached != null) return cached;
      final processed = _getProcessedImage(placement);
      final png = Uint8List.fromList(img.encodePng(processed, level: 6));
      _encodedPngCache[key] = png;
      return png;
    }

    // Wrap bytes in a pw.MemoryImage with caching.
    pw.MemoryImage? _getMemoryImage(Uint8List bytes, String key) {
      final cached = _memoryImageCache[key];
      if (cached != null) return cached;
      try {
        final imgObj = pw.MemoryImage(bytes);
        _memoryImageCache[key] = imgObj;
        return imgObj;
      } catch (_) {
        return null;
      }
    }

    // Compute and cache aspect ratio (width/height) for given image
    double? _getAspectRatioFromImage(img.Image image) {
      final key = _baseKeyForImage(image);
      final c = _aspectRatioCache[key];
      if (c != null) return c;
      if (image.width <= 0 || image.height <= 0) return null;
      final ar = image.width / image.height;
      _aspectRatioCache[key] = ar;
      return ar;
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

                  // Get processed image and embed as MemoryImage (cached)
                  final processedPng = _getProcessedPng(placement);
                  final baseImage = _getBaseImage(placement);
                  final memKey =
                      '${_baseKeyForImage(baseImage)}|${_adjustKey(placement.graphicAdjust)}';
                  if (processedPng.isNotEmpty) {
                    final imgObj = _getMemoryImage(processedPng, memKey);
                    if (imgObj != null) {
                      // Align with RotatedSignatureImage: counterclockwise positive
                      final angle = rot.radians(placement.rotationDeg);
                      // Use AR from base image
                      final ar = _getAspectRatioFromImage(baseImage);
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

                final processedPng = _getProcessedPng(placement);
                final baseImage = _getBaseImage(placement);
                final memKey =
                    '${_baseKeyForImage(baseImage)}|${_adjustKey(placement.graphicAdjust)}';
                if (processedPng.isNotEmpty) {
                  final imgObj = _getMemoryImage(processedPng, memKey);
                  if (imgObj != null) {
                    final angle = rot.radians(placement.rotationDeg);
                    final ar = _getAspectRatioFromImage(baseImage);
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

  // Background removal implemented in utils/background_removal.dart
}
