import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/signature_card_repository.dart';
import '_world.dart';

/// Usage: {2} signature cards exist
Future<void> signatureCardsExist(WidgetTester tester, num param1) async {
  final expected = param1.toInt();
  final c = TestWorld.container ?? ProviderContainer();
  final cards = c.read(signatureCardRepositoryProvider);
  expect(cards.length, expected);
}
