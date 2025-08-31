import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: the user places two signatures on the same page
Future<void> theUserPlacesTwoSignaturesOnTheSamePage(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  container
      .read(signatureProvider.notifier)
      .setImageBytes(Uint8List.fromList([1, 2, 3]));
  // First
  container.read(signatureProvider.notifier).placeDefaultRect();
  final r1 = container.read(signatureProvider).rect!;
  container.read(pdfProvider.notifier).addPlacement(page: 1, rect: r1);
  // Second (offset a bit)
  final r2 = r1.shift(const Offset(30, 30));
  container.read(pdfProvider.notifier).addPlacement(page: 1, rect: r2);
}
