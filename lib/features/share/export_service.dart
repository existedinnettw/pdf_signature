import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/widgets.dart' as pw;

// NOTE:
// - This exporter uses a raster snapshot of the UI (RepaintBoundary) and embeds it into a new PDF.
// - It does NOT perform vector-accurate stamping into the source PDF.
// - Vector stamping remains unimplemented with FOSS-only constraints because the `pdf` package
//   cannot import/modify existing PDF pages. If/when a suitable FOSS library exists, wire it here.

class ExportService {
  Future<bool> exportSignedPdfFromBoundary({
    required GlobalKey boundaryKey,
    required String outputPath,
  }) async {
    try {
      final boundary =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return false;
      // Render current view to image
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return false;
      final pngBytes = byteData.buffer.asUint8List();

      // Compose single-page PDF with the image
      final doc = pw.Document();
      final img = pw.MemoryImage(pngBytes);
      doc.addPage(
        pw.Page(
          build:
              (context) =>
                  pw.Center(child: pw.Image(img, fit: pw.BoxFit.contain)),
        ),
      );
      final bytes = await doc.save();
      final file = File(outputPath);
      await file.writeAsBytes(bytes, flush: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Multi-page export by navigating the viewer and capturing each page.
  /// onGotoPage must navigate the UI to the requested page and return when the
  /// page is ready to render. We'll still wait for a frame for safety.
  Future<bool> exportMultiPageFromBoundary({
    required GlobalKey boundaryKey,
    required String outputPath,
    required int pageCount,
    required Future<void> Function(int page) onGotoPage,
    double pixelRatio = 3.0,
  }) async {
    try {
      final doc = pw.Document();
      for (int i = 1; i <= pageCount; i++) {
        await onGotoPage(i);
        // Give Flutter and the PDF viewer time to render the page
        await Future<void>.delayed(const Duration(milliseconds: 120));
        for (int f = 0; f < 2; f++) {
          try {
            await WidgetsBinding.instance.endOfFrame;
          } catch (_) {
            // Best-effort if not in a frame-driven context
            await Future<void>.delayed(const Duration(milliseconds: 16));
          }
        }

        final boundary =
            boundaryKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;
        if (boundary == null) return false;
        final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) return false;
        final pngBytes = byteData.buffer.asUint8List();
        final img = pw.MemoryImage(pngBytes);
        doc.addPage(
          pw.Page(
            build:
                (context) =>
                    pw.Center(child: pw.Image(img, fit: pw.BoxFit.contain)),
          ),
        );
      }
      final bytes = await doc.save();
      final file = File(outputPath);
      await file.writeAsBytes(bytes, flush: true);
      return true;
    } catch (e) {
      return false;
    }
  }
}
