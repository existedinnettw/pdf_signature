import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/signature_library_repository.dart';
import 'package:pdf_signature/data/repositories/pdf_repository.dart';
import 'package:pdf_signature/data/repositories/signature_repository.dart';
import 'package:pdf_signature/data/model/model.dart';
import '_world.dart';

/// Usage: a signature asset is loaded or drawn
Future<void> aSignatureAssetIsLoadedOrDrawn(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  container.read(signatureLibraryProvider.notifier).state = [];
  container.read(pdfProvider.notifier).state = PdfState.initial();
  container.read(signatureProvider.notifier).state = SignatureState.initial();
  final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
  container
      .read(signatureLibraryProvider.notifier)
      .add(bytes, name: 'test.png');
}
