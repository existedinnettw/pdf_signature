import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: a new PDF file is saved at specified full path, location and file name
Future<void> aNewPdfFileIsSavedAtSpecifiedFullPathLocationAndFileName(
  WidgetTester tester,
) async {
  if (TestWorld.lastSavedPath != null) {
    expect(File(TestWorld.lastSavedPath!).existsSync(), isTrue);
  } else {
    expect(TestWorld.lastExportBytes, isNotNull);
    expect(TestWorld.lastExportBytes!.isNotEmpty, isTrue);
  }
}
