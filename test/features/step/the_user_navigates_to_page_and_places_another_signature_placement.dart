import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/pdf_providers.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import '_world.dart';

/// Usage: the user navigates to page {5} and places another signature placement
Future<void> theUserNavigatesToPageAndPlacesAnotherSignaturePlacement(
  WidgetTester tester,
  num param1,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final page = param1.toInt();
  // Update page providers directly (repository jumpTo is a no-op now)
  try {
    container.read(currentPageProvider.notifier).state = page;
  } catch (_) {}
  try {
    container.read(pdfViewModelProvider.notifier).jumpToPage(page);
  } catch (_) {}
  container
      .read(documentRepositoryProvider.notifier)
      .addPlacement(
        page: page,
        rect: Rect.fromLTWH(40, 40, 100, 50),
        asset: SignatureAsset(bytes: Uint8List(0), name: 'another.png'),
      );
}
