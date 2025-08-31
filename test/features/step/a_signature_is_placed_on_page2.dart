import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: a signature is placed on page 2
Future<void> aSignatureIsPlacedOnPage2(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  container
      .read(pdfProvider.notifier)
      .openPicked(path: 'mock.pdf', pageCount: 5);
  container
      .read(signatureProvider.notifier)
      .setImageBytes(Uint8List.fromList([1, 2, 3]));
  container.read(signatureProvider.notifier).placeDefaultRect();
  final r = container.read(signatureProvider).rect!;
  container.read(pdfProvider.notifier).addPlacement(page: 2, rect: r);
  expect(container.read(pdfProvider.notifier).placementsOn(2), isNotEmpty);
}
