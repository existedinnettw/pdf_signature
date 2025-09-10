import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import '_world.dart';

/// Usage: the user deletes one selected signature placement
Future<void> theUserDeletesOneSelectedSignaturePlacement(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final pdf = container.read(documentRepositoryProvider);
  if (pdf.selectedPlacementIndex == null) {
    container.read(documentRepositoryProvider.notifier).selectPlacement(0);
  }
  container.read(documentRepositoryProvider.notifier).deleteSelectedPlacement();
}
