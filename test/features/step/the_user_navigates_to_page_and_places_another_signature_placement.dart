import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import '_world.dart';

/// Usage: the user navigates to page {5} and places another signature placement
Future<void> theUserNavigatesToPageAndPlacesAnotherSignaturePlacement(
  WidgetTester tester,
  num param1,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final page = param1.toInt();
  container.read(documentRepositoryProvider.notifier).jumpTo(page);
  container
      .read(documentRepositoryProvider.notifier)
      .addPlacement(
        page: page,
        rect: Rect.fromLTWH(40, 40, 100, 50),
        asset: SignatureAsset(
          id: 'another.png',
          bytes: Uint8List(0),
          name: 'another.png',
        ),
      );
}
