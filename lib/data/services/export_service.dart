import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import 'package:printing/printing.dart' as printing;
import 'package:image/image.dart' as img;
import '../model/model.dart';

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
  /// - [signedPage]: 1-based page index to place the signature on (null = no overlay)
  /// - [signatureRectUi]: Rect in the UI's logical page space (e.g. 400x560)
  /// - [uiPageSize]: The logical page size used by the UI layout (SignatureController.pageSize)
  /// - [signatureImageBytes]: PNG/JPEG bytes of the signature image to overlay
  /// - [targetDpi]: Rasterization DPI for background pages
  Future<bool> exportSignedPdfFromFile({
    required String inputPath,
    required String outputPath,
    required int? signedPage,
    required Rect? signatureRectUi,
    required Size uiPageSize,
    required Uint8List? signatureImageBytes,
    Map<int, List<SignaturePlacement>>? placementsByPage,
    Map<String, Uint8List>? libraryBytes,
    double targetDpi = 144.0,
  }) async {
    // print(
    //   'exportSignedPdfFromFile: enter signedPage=$signedPage outputPath=$outputPath',
    // );
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
      signedPage: signedPage,
      signatureRectUi: signatureRectUi,
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
    required int? signedPage,
    required Rect? signatureRectUi,
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

        pw.MemoryImage? sigImgObj;
        final hasMulti =
            (placementsByPage != null && placementsByPage.isNotEmpty);
        final pagePlacements =
            hasMulti
                ? (placementsByPage[pageIndex] ?? const <SignaturePlacement>[])
                : const <SignaturePlacement>[];
        final shouldStampSingle =
            !hasMulti &&
            signedPage != null &&
            pageIndex == signedPage &&
            signatureRectUi != null &&
            signatureImageBytes != null &&
            signatureImageBytes.isNotEmpty;
        if (shouldStampSingle) {
          try {
            sigImgObj = pw.MemoryImage(signatureImageBytes);
          } catch (_) {
            sigImgObj = null;
          }
        }

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
                  Uint8List? bytes;
                  final id = placement.assetId;
                  if (id.isNotEmpty) {
                    bytes = libraryBytes?[id];
                  }
                  bytes ??= signatureImageBytes; // fallback
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
              } else if (shouldStampSingle && sigImgObj != null) {
                final r = signatureRectUi;
                final left = r.left / uiPageSize.width * widthPts;
                final top = r.top / uiPageSize.height * heightPts;
                final w = r.width / uiPageSize.width * widthPts;
                final h = r.height / uiPageSize.height * heightPts;
                children.add(
                  pw.Positioned(
                    left: left,
                    top: top,
                    child: pw.SizedBox(
                      width: w,
                      height: h,
                      child: pw.FittedBox(
                        fit: pw.BoxFit.contain,
                        child: pw.Image(sigImgObj),
                      ),
                    ),
                  ),
                );
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
      pw.MemoryImage? sigImgObj;
      final hasMulti =
          (placementsByPage != null && placementsByPage.isNotEmpty);
      final pagePlacements =
          hasMulti
              ? (placementsByPage[1] ?? const <SignaturePlacement>[])
              : const <SignaturePlacement>[];
      final shouldStampSingle =
          !hasMulti &&
          signedPage != null &&
          signedPage == 1 &&
          signatureRectUi != null &&
          signatureImageBytes != null &&
          signatureImageBytes.isNotEmpty;
      if (shouldStampSingle) {
        try {
          // If it's already PNG, keep as-is to preserve alpha; otherwise decode/encode PNG
          final asStr = String.fromCharCodes(signatureImageBytes.take(8));
          final isPng =
              signatureImageBytes.length > 8 &&
              signatureImageBytes[0] == 0x89 &&
              asStr.startsWith('\u0089PNG');
          if (isPng) {
            sigImgObj = pw.MemoryImage(signatureImageBytes);
          } else {
            final decoded = img.decodeImage(signatureImageBytes);
            if (decoded != null) {
              final png = img.encodePng(decoded, level: 6);
              sigImgObj = pw.MemoryImage(Uint8List.fromList(png));
            }
          }
        } catch (_) {}
      }
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
                Uint8List? bytes;
                final id = placement.assetId;
                if (id.isNotEmpty) {
                  bytes = libraryBytes?[id];
                }
                bytes ??= signatureImageBytes; // fallback
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
            } else if (shouldStampSingle && sigImgObj != null) {
              final r = signatureRectUi;
              final left = r.left / uiPageSize.width * widthPts;
              final top = r.top / uiPageSize.height * heightPts;
              final w = r.width / uiPageSize.width * widthPts;
              final h = r.height / uiPageSize.height * heightPts;
              children.add(
                pw.Positioned(
                  left: left,
                  top: top,
                  child: pw.SizedBox(
                    width: w,
                    height: h,
                    child: pw.FittedBox(
                      fit: pw.BoxFit.contain,
                      child: pw.Image(sigImgObj),
                    ),
                  ),
                ),
              );
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
}
