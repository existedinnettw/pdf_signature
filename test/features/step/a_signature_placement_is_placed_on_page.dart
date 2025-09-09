import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/pdf_repository.dart';
import 'package:pdf_signature/data/model/model.dart';
import '_world.dart';

/// Usage: a signature placement is placed on page {2}
Future<void> aSignaturePlacementIsPlacedOnPage(
  WidgetTester tester,
  num param1,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final page = param1.toInt();
  container
      .read(pdfProvider.notifier)
      .addPlacement(
        page: page,
        rect: Rect.fromLTWH(20, 20, 100, 50),
        asset: SignatureAsset(id: 'test.png', bytes: Uint8List(0)),
      );
}
