import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/document_version.dart';
import 'dart:typed_data';

void main() {
  group('DocumentVersion', () {
    test('should generate consistent source names', () {
      final version1 = DocumentVersion(version: 1);
      final version2 = DocumentVersion(version: 2);

      expect(version1.sourceName, 'document_v1.pdf');
      expect(version2.sourceName, 'document_v2.pdf');
    });

    test('should increment version when bytes change', () {
      final bytes1 = Uint8List.fromList([1, 2, 3]);
      final bytes2 = Uint8List.fromList([4, 5, 6]);

      final version = DocumentVersion(version: 1, lastBytes: bytes1);

      expect(version.shouldIncrementVersion(bytes2), true);
      expect(version.shouldIncrementVersion(bytes1), false);
    });

    test('should detect identical bytes correctly', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final version = DocumentVersion(version: 1, lastBytes: bytes);

      // Same bytes object should not trigger increment
      expect(version.shouldIncrementVersion(bytes), false);
    });
  });
}
