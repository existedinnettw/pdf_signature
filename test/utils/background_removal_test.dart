import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pdf_signature/utils/background_removal.dart';

void main() {
  group('removeNearWhiteBackground', () {
    test('makes pure white transparent and keeps black opaque', () {
      final im = img.Image(width: 2, height: 1);
      // Left pixel white, right pixel black
      im.setPixel(0, 0, img.ColorRgb8(255, 255, 255));
      im.setPixel(1, 0, img.ColorRgb8(0, 0, 0));

      final out = removeNearWhiteBackground(im, threshold: 240);

      final pWhite = out.getPixel(0, 0);
      final pBlack = out.getPixel(1, 0);
      expect(pWhite.a, 0, reason: 'white should become transparent');
      expect(pBlack.a, 255, reason: 'black should remain opaque');
    });

    test(
      'near-white above threshold becomes transparent, below stays opaque',
      () {
        final im = img.Image(width: 3, height: 1);
        im.setPixel(0, 0, img.ColorRgb8(239, 239, 239)); // below 240
        im.setPixel(1, 0, img.ColorRgb8(240, 240, 240)); // at threshold
        im.setPixel(2, 0, img.ColorRgb8(250, 250, 250)); // above threshold

        final out = removeNearWhiteBackground(im, threshold: 240);

        expect(out.getPixel(0, 0).a, 255, reason: '239 should stay opaque');
        expect(out.getPixel(1, 0).a, 0, reason: '240 should be transparent');
        expect(out.getPixel(2, 0).a, 0, reason: '250 should be transparent');
      },
    );

    test('preserves color channels while zeroing alpha for near-white', () {
      final im = img.Image(width: 1, height: 1);
      im.setPixel(0, 0, img.ColorRgb8(245, 246, 247));

      final out = removeNearWhiteBackground(im, threshold: 240);
      final p = out.getPixel(0, 0);
      expect(p.r, 245);
      expect(p.g, 246);
      expect(p.b, 247);
      expect(p.a, 0);
    });

    test('works when input already has alpha channel', () {
      final im = img.Image(width: 1, height: 2, numChannels: 4);
      im.setPixel(0, 0, img.ColorRgba8(255, 255, 255, 200));
      im.setPixel(0, 1, img.ColorRgba8(10, 10, 10, 123));

      final out = removeNearWhiteBackground(im, threshold: 240);
      expect(out.getPixel(0, 0).a, 0, reason: 'white alpha -> 0');
      expect(out.getPixel(0, 1).a, 123, reason: 'non-white alpha preserved');
    });

    test(
      'real image: test/data/test_signature_image.png background becomes transparent',
      () {
        final path = 'test/data/test_signature_image.png';
        final file = File(path);
        if (!file.existsSync()) {
          // Fallback: create a simple signature-like PNG if missing
          Directory('test/data').createSync(recursive: true);
          final w = 200, h = 100;
          final canvas = img.Image(width: w, height: h);
          img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
          for (int dy = -1; dy <= 1; dy++) {
            img.drawLine(
              canvas,
              x1: 20,
              y1: h ~/ 2 + dy,
              x2: w - 20,
              y2: h ~/ 2 + dy,
              color: img.ColorRgb8(0, 0, 0),
            );
          }
          img.drawLine(
            canvas,
            x1: w - 50,
            y1: h ~/ 2 - 10,
            x2: w - 10,
            y2: h ~/ 2 - 20,
            color: img.ColorRgb8(0, 0, 0),
          );
          file.writeAsBytesSync(img.encodePng(canvas));
        }

        final bytes = file.readAsBytesSync();
        final decoded = img.decodeImage(bytes);
        expect(decoded, isNotNull, reason: 'should decode test image');
        final processed = removeNearWhiteBackground(decoded!, threshold: 240);

        // Corners are often paper margin: expect transparency where near-white
        final c00 = processed.getPixel(0, 0);
        final c10 = processed.getPixel(processed.width - 1, 0);
        final c01 = processed.getPixel(0, processed.height - 1);
        final c11 = processed.getPixel(
          processed.width - 1,
          processed.height - 1,
        );
        // If any corner is near-white, it should be transparent
        bool anyCornerTransparent = false;
        for (final p in [c00, c10, c01, c11]) {
          if (p.r >= 240 && p.g >= 240 && p.b >= 240) {
            expect(p.a, 0, reason: 'near-white corner should be transparent');
            anyCornerTransparent = true;
          }
        }
        expect(
          anyCornerTransparent,
          isTrue,
          reason: 'expected at least one near-white corner in the test image',
        );

        // Find a dark pixel and assert it remains opaque
        bool foundDarkOpaque = false;
        for (int y = 0; y < processed.height && !foundDarkOpaque; y++) {
          for (int x = 0; x < processed.width && !foundDarkOpaque; x++) {
            final p = processed.getPixel(x, y);
            if (p.r < 50 && p.g < 50 && p.b < 50) {
              expect(p.a, 255, reason: 'dark stroke pixel should stay opaque');
              foundDarkOpaque = true;
            }
          }
        }
        expect(
          foundDarkOpaque,
          isTrue,
          reason: 'expected at least one dark stroke pixel in the test image',
        );
      },
    );
  });
}
