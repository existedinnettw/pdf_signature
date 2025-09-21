import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdfrx_engine/pdfrx_engine.dart' as engine;
import '../../domain/models/model.dart';
import '../../utils/rotation_utils.dart' as rot;
import '../../utils/background_removal.dart' as br;

// NOTE:
// - This exporter uses a raster snapshot of the UI (RepaintBoundary) and embeds it into a new PDF.
// - It does NOT perform vector-accurate stamping into the source PDF.
// - Vector stamping remains unimplemented with FOSS-only constraints because the `pdf` package
//   cannot import/modify existing PDF pages. If/when a suitable FOSS library exists, wire it here.

class ExportService {
  ExportService({this.enableRaster = true});
  // Deprecated: retained for API compatibility. Raster is no longer used.
  final bool enableRaster;

  /// Compose a new PDF by rendering source pages to images (FOSS path via pdfrx)
  /// and overlaying signature images at normalized rects. Returns resulting bytes.
  Future<Uint8List?> exportSignedPdfFromBytes({
    required Uint8List srcBytes,
    required Size uiPageSize, // not used in this implementation
    required Uint8List?
    signatureImageBytes, // not used; placements carry images
    Map<int, List<SignaturePlacement>>? placementsByPage,
    Map<String, img.Image>? libraryImages,
    double targetDpi = 144.0,
  }) async {
    // Caches per call
    final Map<String, img.Image> _baseImageCache = <String, img.Image>{};
    final Map<String, img.Image> _processedImageCache = <String, img.Image>{};
    final Map<String, Uint8List> _encodedPngCache = <String, Uint8List>{};
    final Map<String, double> _aspectRatioCache = <String, double>{};

    String _baseKeyForImage(img.Image im) =>
        'im:${identityHashCode(im)}:${im.width}x${im.height}';
    String _adjustKey(GraphicAdjust adj) =>
        'c=${adj.contrast}|b=${adj.brightness}|bg=${adj.bgRemoval}';

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
      Future<void> _ = Future<void>.delayed(Duration.zero);
      if (adj.bgRemoval) {
        processed = br.removeNearWhiteBackground(processed, threshold: 240);
      }
      Future<void> _ = Future<void>.delayed(Duration.zero);
      _processedImageCache[key] = processed;
      return processed;
    }

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

    double? _getAspectRatioFromImage(img.Image image) {
      final key = _baseKeyForImage(image);
      final c = _aspectRatioCache[key];
      if (c != null) return c;
      if (image.width <= 0 || image.height <= 0) return null;
      final ar = image.width / image.height;
      _aspectRatioCache[key] = ar;
      return ar;
    }

    // Initialize engine (safe to call multiple times)
    try {
      await engine.pdfrxInitialize();
    } catch (_) {}

    // Open source document from memory; if not supported, write temp file
    engine.PdfDocument? doc;
    try {
      doc = await engine.PdfDocument.openData(srcBytes);
    } catch (_) {
      final tmp = File(
        '${Directory.systemTemp.path}/pdfrx_src_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await tmp.writeAsBytes(srcBytes, flush: true);
      doc = await engine.PdfDocument.openFile(tmp.path);
      try {
        tmp.deleteSync();
      } catch (_) {}
    }
    // doc is guaranteed to be assigned by either openData or openFile above

    final out = pw.Document(version: pdf.PdfVersion.pdf_1_4, compress: false);
    final pages = doc.pages;
    final scale = targetDpi / 72.0;
    for (int i = 0; i < pages.length; i++) {
      // Cooperative yield between pages so the UI can animate the spinner.
      await Future<void>.delayed(Duration.zero);
      final page = pages[i];
      final pageIndex = i + 1;
      final widthPts = page.width;
      final heightPts = page.height;

      // Render background image via engine
      final imgPage = await page.render(
        fullWidth: widthPts * scale,
        fullHeight: heightPts * scale,
      );
      if (imgPage == null) continue;
      final bgImage = imgPage.createImageNF();
      imgPage.dispose();
      // Lower compression for background snapshot too.
      final bgPng = Uint8List.fromList(img.encodePng(bgImage, level: 1));
      final _ = Future<void>.delayed(Duration.zero);
      final bgMem = pw.MemoryImage(bgPng);

      final pagePlacements =
          (placementsByPage ??
              const <int, List<SignaturePlacement>>{})[pageIndex] ??
          const <SignaturePlacement>[];

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
                  bgMem,
                  width: widthPts,
                  height: heightPts,
                  fit: pw.BoxFit.fill,
                ),
              ),
            ];

            for (final placement in pagePlacements) {
              final r = placement.rect;
              final left = r.left * widthPts;
              final top = r.top * heightPts;
              final w = r.width * widthPts;
              final h = r.height * heightPts;

              final processedPng = _getProcessedPng(placement);
              if (processedPng.isEmpty) continue;
              final memImg = pw.MemoryImage(processedPng);
              final angle = rot.radians(placement.rotationDeg);
              final baseImage = _getBaseImage(placement);
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
                          child: pw.Image(memImg),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              // Yield occasionally within large placement lists to keep UI responsive.
              // ignore: unused_local_variable
              final _ = Future<void>.delayed(Duration.zero);
            }
            return pw.Stack(children: children);
          },
        ),
      );
      final _ = Future<void>.delayed(Duration.zero);
    }

    final bytes = await out.save();
    doc.dispose();
    return bytes;
  }

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
