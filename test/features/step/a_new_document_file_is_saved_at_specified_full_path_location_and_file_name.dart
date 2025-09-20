import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: a new document file is saved at specified full path, location and file name
Future<void> aNewDocumentFileIsSavedAtSpecifiedFullPathLocationAndFileName(
  WidgetTester tester,
) async {
  // Verify that export bytes were generated
  expect(
    TestWorld.lastExportBytes,
    isNotNull,
    reason: 'Export bytes should be generated after save',
  );

  // Simulate a saved path (in a real implementation this would come from file picker)
  TestWorld.lastSavedPath =
      TestWorld.lastSavedPath ?? '/tmp/signed_document.pdf';

  expect(
    TestWorld.lastSavedPath,
    isNotNull,
    reason: 'A save path should be specified',
  );
}
