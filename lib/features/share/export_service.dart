import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/widgets.dart' as pw;

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
}
