import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import 'package:printing/printing.dart' as printing;
import 'package:image/image.dart' as img;

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
        final shouldStamp =
            signedPage != null &&
            pageIndex == signedPage &&
            signatureRectUi != null &&
            signatureImageBytes != null &&
            signatureImageBytes.isNotEmpty;
        if (shouldStamp) {
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
              if (sigImgObj != null) {
                final r = signatureRectUi!;
                final left = r.left / uiPageSize.width * widthPts;
                final top = r.top / uiPageSize.height * heightPts;
                final w = r.width / uiPageSize.width * widthPts;
                final h = r.height / uiPageSize.height * heightPts;
                children.add(
                  pw.Positioned(
                    left: left,
                    top: top,
                    child: pw.Image(sigImgObj, width: w, height: h),
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
      final shouldStamp =
          signedPage != null &&
          signedPage == 1 &&
          signatureRectUi != null &&
          signatureImageBytes != null &&
          signatureImageBytes.isNotEmpty;
      if (shouldStamp) {
        try {
          final decoded = img.decodeImage(signatureImageBytes);
          if (decoded != null) {
            final jpg = img.encodeJpg(decoded, quality: 90);
            sigImgObj = pw.MemoryImage(Uint8List.fromList(jpg));
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
            if (sigImgObj != null) {
              final r = signatureRectUi!;
              final left = r.left / uiPageSize.width * widthPts;
              final top = r.top / uiPageSize.height * heightPts;
              final w = r.width / uiPageSize.width * widthPts;
              final h = r.height / uiPageSize.height * heightPts;
              children.add(
                pw.Positioned(
                  left: left,
                  top: top,
                  child: pw.Image(sigImgObj, width: w, height: h),
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
