import 'dart:typed_data';
import 'dart:ui' show Rect, Size;
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '_world.dart';

// A lightweight fake exporter to avoid platform rasterization in tests.
class FakeExportService {
  Future<bool> exportSignedPdfFromFile({
    required String inputPath,
    required String outputPath,
    required int? signedPage,
    required Rect? signatureRectUi,
    required Size uiPageSize,
    required Uint8List? signatureImageBytes,
    double targetDpi = 144.0,
  }) async {
    final bytes = await exportSignedPdfFromBytes(
      srcBytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46]),
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

  Future<Uint8List?> exportSignedPdfFromBytes({
    required Uint8List srcBytes,
    required int? signedPage,
    required Rect? signatureRectUi,
    required Size uiPageSize,
    required Uint8List? signatureImageBytes,
    double targetDpi = 144.0,
  }) async {
    // Return a deterministic tiny PDF-like byte array
    final header = <int>[0x25, 0x50, 0x44, 0x46, 0x2D]; // %PDF-
    final payload = <int>[...srcBytes.take(4)];
    final sigFlag =
        (signatureRectUi != null &&
                signatureImageBytes != null &&
                signatureImageBytes.isNotEmpty)
            ? 1
            : 0;
    final meta = <int>[
      sigFlag,
      uiPageSize.width.toInt() & 0xFF,
      uiPageSize.height.toInt() & 0xFF,
    ];
    return Uint8List.fromList([...header, ...payload, ...meta]);
  }
}

ProviderContainer getOrCreateContainer() {
  if (TestWorld.container != null) return TestWorld.container!;
  final container = ProviderContainer();
  TestWorld.container = container;
  return container;
}
