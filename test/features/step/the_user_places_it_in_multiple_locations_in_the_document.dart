import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import '_world.dart';

/// Usage: the user places it in multiple locations in the document
Future<void> theUserPlacesItInMultipleLocationsInTheDocument(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final notifier = container.read(documentRepositoryProvider.notifier);
  // Always open a fresh doc to avoid state bleed between scenarios
  notifier.openPicked(path: 'mock.pdf', pageCount: 6);
  // Place two on page 2 and one on page 4
  notifier.addPlacement(page: 2, rect: const Rect.fromLTWH(10, 10, 80, 40));
  notifier.addPlacement(page: 2, rect: const Rect.fromLTWH(120, 50, 80, 40));
  notifier.addPlacement(page: 4, rect: const Rect.fromLTWH(20, 200, 100, 50));
}
