import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import '_world.dart';

/// Usage: the user places a signature placement on page {1}
Future<void> theUserPlacesASignaturePlacementOnPage(
  WidgetTester tester,
  num param1,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final page = param1.toInt();
  container
      .read(documentRepositoryProvider.notifier)
      .addPlacement(
        page: page,
        rect: Rect.fromLTWH(20, 20, 100, 50),
        asset: SignatureAsset(
          sigImage: img.Image(width: 1, height: 1),
          name: 'test.png',
        ),
      );
  // Allow Riverpod's scheduler to flush any pending microtasks/timers
  await tester.pumpAndSettle();
}
