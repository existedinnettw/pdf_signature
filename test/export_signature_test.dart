import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Rect, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;

import 'package:pdf_signature/data/services/export_service.dart';

void main() {
  test(
    'exportSignedPdfFromFile overlays signature image (structure/size check)',
    () async {
      // 1) Create a simple 1-page white PDF as the source
      final srcDoc = pw.Document();
      srcDoc.addPage(
        pw.Page(
          pageFormat: pdf.PdfPageFormat.a4,
          build: (_) => pw.Container(color: pdf.PdfColors.white),
        ),
      );
      final srcBytes = await srcDoc.save();
      final srcPath =
          '${Directory.systemTemp.path}/export_src_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await File(srcPath).writeAsBytes(srcBytes, flush: true);

      // 2) Create a small opaque black PNG as the signature image
      final sigW = 60, sigH = 30;
      final sigBitmap = img.Image(width: sigW, height: sigH);
      img.fill(sigBitmap, color: img.ColorRgb8(0, 0, 0));
      final sigPng = Uint8List.fromList(img.encodePng(sigBitmap));

      // 3) Define signature rect in UI logical space (400x560), centered
      const uiSize = Size(400, 560);
      final r = Rect.fromLTWH(
        uiSize.width / 2 - sigW / 2,
        uiSize.height / 2 - sigH / 2,
        sigW.toDouble(),
        sigH.toDouble(),
      );

      // 4) Baseline export without signature (no overlay)
      final baselinePath =
          '${Directory.systemTemp.path}/export_baseline_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final svc = ExportService();
      final okBase = await svc.exportSignedPdfFromFile(
        inputPath: srcPath,
        outputPath: baselinePath,
        signedPage: null,
        signatureRectUi: null,
        uiPageSize: uiSize,
        signatureImageBytes: null,
        targetDpi: 144.0,
      );
      expect(okBase, isTrue, reason: 'baseline export should succeed');
      final baseBytes = await File(baselinePath).readAsBytes();
      expect(baseBytes.isNotEmpty, isTrue);

      // 5) Export with overlay
      final outPath =
          '${Directory.systemTemp.path}/export_out_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final ok = await svc.exportSignedPdfFromFile(
        inputPath: srcPath,
        outputPath: outPath,
        signedPage: 1,
        signatureRectUi: r,
        uiPageSize: uiSize,
        signatureImageBytes: sigPng,
        targetDpi: 144.0,
      );
      expect(ok, isTrue, reason: 'export should succeed');
      final outBytes = await File(outPath).readAsBytes();
      expect(outBytes.isNotEmpty, isTrue);

      // 6) Heuristic validations without rasterization:
      // - The output with overlay should be larger than the baseline.
      // - The output should contain at least one image object marker.
      expect(outBytes.length, greaterThan(baseBytes.length));
      // Decode as latin1 to preserve byte-to-char mapping, then look for the image marker
      final outText = String.fromCharCodes(outBytes);
      final hasImageMarker = RegExp(r"/Subtype\s*/Image").hasMatch(outText);
      expect(hasImageMarker, isTrue);
    },
  );
}
