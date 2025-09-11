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
  final placements = container
      .read(documentRepositoryProvider.notifier)
      .placementsOn();
  if (placements.isNotEmpty) {
    container
        .read(documentRepositoryProvider.notifier)
        .removePlacement(page: , index: 0);
  }
}
