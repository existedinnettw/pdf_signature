import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '_world.dart';

/// Usage: the user chooses undo
Future<void> theUserChoosesUndo(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  final sig = container.read(signatureProvider);
  if (sig.strokes.isNotEmpty) {
    final newStrokes = List<List<Offset>>.from(sig.strokes)..removeLast();
    container.read(signatureProvider.notifier).setStrokes(newStrokes);
  }
}
