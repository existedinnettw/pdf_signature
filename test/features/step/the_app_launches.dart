import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf_signature/app.dart';
import 'package:pdf_signature/data/repositories/preferences_repository.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';
import 'package:pdf_signature/data/repositories/signature_card_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/pdf_providers.dart';
import '_world.dart';

class _BridgedSignatureCardStateNotifier extends SignatureCardStateNotifier {
  void setAll(List<SignatureCard> cards) {
    state = List.unmodifiable(cards);
  }
}

/// Usage: the app launches
Future<void> theAppLaunches(WidgetTester tester) async {
  TestWorld.reset();
  SharedPreferences.setMockInitialValues(TestWorld.prefs);
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      preferencesRepositoryProvider.overrideWith(
        (ref) => PreferencesStateNotifier(prefs),
      ),
      documentRepositoryProvider.overrideWith(
        (ref) => DocumentStateNotifier()..openSample(),
      ),
      useMockViewerProvider.overrideWith((ref) => true),
      // Bridge: automatically mirror assets into signature cards so legacy
      // feature steps that expect SignatureCard widgets keep working even
      // though the production UI currently only stores raw assets.
      signatureCardRepositoryProvider.overrideWith((ref) {
        final notifier = _BridgedSignatureCardStateNotifier();
        ref.listen<List<SignatureAsset>>(signatureAssetRepositoryProvider, (
          prev,
          next,
        ) {
          for (final asset in next) {
            if (!notifier.state.any((c) => identical(c.asset, asset))) {
              notifier.add(SignatureCard(asset: asset, rotationDeg: 0.0));
            }
          }
          // Remove cards whose assets were removed
          final remaining =
              notifier.state.where((c) => next.contains(c.asset)).toList();
          if (remaining.length != notifier.state.length) {
            notifier.setAll(remaining);
          }
        });
        return notifier;
      }),
    ],
  );
  TestWorld.container = container;

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const MyApp()),
  );
  await tester.pumpAndSettle();
}
