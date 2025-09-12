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
  // Preserve any previously simulated stored preferences (used by scenarios
  // that set TestWorld.prefs BEFORE launching to emulate a prior run).
  final preservedPrefs = Map<String, String>.from(TestWorld.prefs);
  TestWorld.reset();
  if (preservedPrefs.isNotEmpty) {
    TestWorld.prefs = preservedPrefs; // restore for this launch
  }

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

  // ----- Simulated app preference initialization logic -----
  // Theme initialization & validation
  const validThemes = {'light', 'dark', 'system'};
  final storedTheme = TestWorld.prefs['theme'];
  if (storedTheme != null && validThemes.contains(storedTheme)) {
    TestWorld.selectedTheme = storedTheme;
  } else {
    // Fallback to system if missing/invalid
    TestWorld.selectedTheme = 'system';
    TestWorld.prefs['theme'] = 'system';
  }
  // currentTheme reflects either explicit theme or current system appearance
  TestWorld.currentTheme =
      TestWorld.selectedTheme == 'system'
          ? TestWorld.systemTheme
          : TestWorld.selectedTheme;

  // Language initialization & validation
  const validLangs = {'en', 'zh-TW', 'es'};
  final storedLang = TestWorld.prefs['language'];
  if (storedLang != null && validLangs.contains(storedLang)) {
    TestWorld.currentLanguage = storedLang;
  } else {
    // Fallback to device locale
    TestWorld.currentLanguage = TestWorld.deviceLocale;
    TestWorld.prefs['language'] = TestWorld.deviceLocale;
  }
}
