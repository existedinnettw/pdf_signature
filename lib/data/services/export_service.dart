import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import 'package:printing/printing.dart' as printing;
import 'package:image/image.dart' as img;
import '../../domain/models/model.dart';

// NOTE:
// - This exporter uses a raster snapshot of the UI (RepaintBoundary) and embeds it into a new PDF.
// - It does NOT perform vector-accurate stamping into the source PDF.
// - Vector stamping remains unimplemented with FOSS-only constraints because the `pdf` package
//   cannot import/modify existing PDF pages. If/when a suitable FOSS library exists, wire it here.

class ExportService {
  /// Compose a new PDF by rasterizing the original PDF pages (via pdfrx engine)
  /// and optionally stamping a signature image on the specified page.
  ///
  /// Inputs:
  /// - [inputPath]: Path to the original PDF to read
  /// - [outputPath]: Path to write the composed PDF
  /// - [uiPageSize]: The logical page size used by the UI layout (SignatureCardStateNotifier.pageSize)
  /// - [signatureImageBytes]: PNG/JPEG bytes of the signature image to overlay
  /// - [targetDpi]: Rasterization DPI for background pages
  Future<bool> exportSignedPdfFromFile({
    required String inputPath,
    required String outputPath,
    required Size uiPageSize,
    required Uint8List? signatureImageBytes,
    Map<int, List<SignaturePlacement>>? placementsByPage,
    Map<String, Uint8List>? libraryBytes,
    double targetDpi = 144.0,
  }) async {
    // Read source bytes and delegate to bytes-based exporter
    Uint8List? srcBytes;
    try {
      srcBytes = await File(inputPath).readAsBytes();
    } catch (_) {
      srcBytes = null;
    }
    if (srcBytes == null) return false;
    final bytes = await exportSignedPdfFromBytes(
      srcBytes: srcBytes,
      uiPageSize: uiPageSize,
      signatureImageBytes: signatureImageBytes,
      placementsByPage: placementsByPage,
      libraryBytes: libraryBytes,
      targetDpi: targetDpi,
    );
    if (bytes == null) return false;
    try {
      final file = File(outputPath);
      await file.writeAsBytes(bytes, flush: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Compose a new PDF from source PDF bytes; returns the resulting PDF bytes.
  Future<Uint8List?> exportSignedPdfFromBytes({
    required Uint8List srcBytes,
    required Size uiPageSize,
    required Uint8List? signatureImageBytes,
    Map<int, List<SignaturePlacement>>? placementsByPage,
    Map<String, Uint8List>? libraryBytes,
    double targetDpi = 144.0,
  }) async {
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
                  final left = r.left / uiPageSize.width * widthPts;
                  final top = r.top / uiPageSize.height * heightPts;
                  final w = r.width / uiPageSize.width * widthPts;
                  final h = r.height / uiPageSize.height * heightPts;

                  // Process the signature asset with its graphic adjustments
                  Uint8List? bytes = placement.asset.bytes;
                  if (bytes != null && bytes.isNotEmpty) {
                    try {
                      // Decode the image
                      final decoded = img.decodeImage(bytes);
                      if (decoded != null) {
                        img.Image processed = decoded;

                        // Apply contrast and brightness first
                        if (placement.graphicAdjust.contrast != 1.0 ||
                            placement.graphicAdjust.brightness != 0.0) {
                          processed = img.adjustColor(
                            processed,
                            contrast: placement.graphicAdjust.contrast,
                            brightness: placement.graphicAdjust.brightness,
                          );
                        }

                        // Apply background removal after color adjustments
                        if (placement.graphicAdjust.bgRemoval) {
                          processed = _removeBackground(processed);
                        }

                        // Encode back to PNG to preserve transparency
                        bytes = Uint8List.fromList(img.encodePng(processed));
                      }
                    } catch (e) {
                      // If processing fails, use original bytes
                    }
                  }

                  // Use fallback if no bytes available
                  bytes ??= signatureImageBytes;

                  if (bytes != null && bytes.isNotEmpty) {
                    pw.MemoryImage? imgObj;
                    try {
                      imgObj = pw.MemoryImage(bytes);
                    } catch (_) {
                      imgObj = null;
                    }
                    if (imgObj != null) {
                      children.add(
                        pw.Positioned(
                          left: left,
                          top: top,
                          child: pw.SizedBox(
                            width: w,
                            height: h,
                            child: pw.FittedBox(
                              fit: pw.BoxFit.contain,
                              child: pw.Transform.rotate(
                                angle:
                                    placement.rotationDeg *
                                    3.1415926535 /
                                    180.0,
                                child: pw.Image(imgObj),
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
            // Multi-placement stamping on fallback page
            if (hasMulti && pagePlacements.isNotEmpty) {
              for (var i = 0; i < pagePlacements.length; i++) {
                final placement = pagePlacements[i];
                final r = placement.rect;
                final left = r.left / uiPageSize.width * widthPts;
                final top = r.top / uiPageSize.height * heightPts;
                final w = r.width / uiPageSize.width * widthPts;
                final h = r.height / uiPageSize.height * heightPts;

                // Process the signature asset with its graphic adjustments
                Uint8List? bytes = placement.asset.bytes;
                if (bytes != null && bytes.isNotEmpty) {
                  try {
                    // Decode the image
                    final decoded = img.decodeImage(bytes);
                    if (decoded != null) {
                      img.Image processed = decoded;

                      // Apply contrast and brightness first
                      if (placement.graphicAdjust.contrast != 1.0 ||
                          placement.graphicAdjust.brightness != 0.0) {
                        processed = img.adjustColor(
                          processed,
                          contrast: placement.graphicAdjust.contrast,
                          brightness: placement.graphicAdjust.brightness,
                        );
                      }

                      // Apply background removal after color adjustments
                      if (placement.graphicAdjust.bgRemoval) {
                        processed = _removeBackground(processed);
                      }

                      // Encode back to PNG to preserve transparency
                      bytes = Uint8List.fromList(img.encodePng(processed));
                    }
                  } catch (e) {
                    // If processing fails, use original bytes
                  }
                }

                // Use fallback if no bytes available
                bytes ??= signatureImageBytes;

                if (bytes != null && bytes.isNotEmpty) {
                  pw.MemoryImage? imgObj;
                  try {
                    // Ensure PNG for transparency if not already
                    final asStr = String.fromCharCodes(bytes.take(8));
                    final isPng =
                        bytes.length > 8 &&
                        bytes[0] == 0x89 &&
                        asStr.startsWith('\u0089PNG');
                    if (isPng) {
                      imgObj = pw.MemoryImage(bytes);
                    } else {
                      final decoded = img.decodeImage(bytes);
                      if (decoded != null) {
                        final png = img.encodePng(decoded, level: 6);
                        imgObj = pw.MemoryImage(Uint8List.fromList(png));
                      }
                    }
                  } catch (_) {
                    imgObj = null;
                  }
                  if (imgObj != null) {
                    children.add(
                      pw.Positioned(
                        left: left,
                        top: top,
                        child: pw.SizedBox(
                          width: w,
                          height: h,
                          child: pw.FittedBox(
                            fit: pw.BoxFit.contain,
                            child: pw.Transform.rotate(
                              angle:
                                  placement.rotationDeg * 3.1415926535 / 180.0,
                              child: pw.Image(imgObj),
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
