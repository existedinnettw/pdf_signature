import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import '_world.dart';

/// Usage: the user places two signature placements on the same page
Future<void> theUserPlacesTwoSignaturePlacementsOnTheSamePage(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final pdf = container.read(documentRepositoryProvider);
  final page = pdf.currentPage;
  container
      .read(documentRepositoryProvider.notifier)
      .addPlacement(
        page: page,
        rect: Rect.fromLTWH(10, 10, 100, 50),
        asset: SignatureAsset(
          id: 'sig1.png',
          bytes: Uint8List(0),
          name: 'sig1.png',
        ),
      );
  container
      .read(documentRepositoryProvider.notifier)
      .addPlacement(
        page: page,
        rect: Rect.fromLTWH(120, 10, 100, 50),
        asset: SignatureAsset(
          id: 'sig2.png',
          bytes: Uint8List(0),
          name: 'sig2.png',
        ),
      );
}
