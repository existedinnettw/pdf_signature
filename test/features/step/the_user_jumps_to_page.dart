import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import '_world.dart';

/// Usage: the user jumps to page {2}
Future<void> theUserJumpsToPage(WidgetTester tester, num param1) async {
  final page = param1.toInt();
  final c = TestWorld.container ?? ProviderContainer();
  c.read(documentRepositoryProvider.notifier).jumpTo(page);
  await tester.pump();
}
