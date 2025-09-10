import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/pdf_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import '_world.dart';

/// Usage: a signature placement is placed with a position and size relative to the page
Future<void> aSignaturePlacementIsPlacedWithAPositionAndSizeRelativeToThePage(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final pdf = container.read(documentRepositoryProvider);
  container
      .read(documentRepositoryProvider.notifier)
      .addPlacement(
        page: pdf.currentPage,
        rect: Rect.fromLTWH(50, 50, 200, 100),
        asset: SignatureAsset(id: 'test.png', bytes: Uint8List(0)),
      );
}
