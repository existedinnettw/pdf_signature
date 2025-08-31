import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: a PDF is open and contains multiple placed signatures across pages
Future<void> aPdfIsOpenAndContainsMultiplePlacedSignaturesAcrossPages(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  container
      .read(pdfProvider.notifier)
      .openPicked(path: 'mock.pdf', pageCount: 6);
  // Ensure signature image exists
  container
      .read(signatureProvider.notifier)
      .setImageBytes(Uint8List.fromList([1, 2, 3]));
  // Place on two pages
  container
      .read(pdfProvider.notifier)
      .addPlacement(page: 1, rect: const Rect.fromLTWH(10, 10, 80, 40));
  container
      .read(pdfProvider.notifier)
      .addPlacement(page: 4, rect: const Rect.fromLTWH(120, 200, 100, 50));
  // Keep backward compatibility with existing export step expectations
  container.read(pdfProvider.notifier).setSignedPage(1);
  container.read(signatureProvider.notifier).placeDefaultRect();
}
