import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/pdf_screen.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import 'package:pdf_signature/ui/features/welcome/widgets/welcome_screen.dart';
import 'data/services/preferences_providers.dart';
import 'package:pdf_signature/ui/features/preferences/widgets/settings_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          // Ensure SharedPreferences loaded before building MaterialApp
          final sp = ref.watch(sharedPreferencesProvider);
          return sp.when(
            loading: () => const SizedBox.shrink(),
            error:
                (e, st) => MaterialApp(
                  onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  home: Builder(
                    builder:
                        (ctx) => Scaffold(
                          body: Center(
                            child: Text(
                              AppLocalizations.of(
                                ctx,
                              ).errorWithMessage(e.toString()),
                            ),
                          ),
                        ),
                  ),
                ),
            data: (_) {
              final themeMode = ref.watch(themeModeProvider);
              final appLocale = ref.watch(localeProvider);
              return MaterialApp(
                onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.indigo,
                    brightness: Brightness.light,
                  ),
                ),
                darkTheme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.indigo,
                    brightness: Brightness.dark,
                  ),
                ),
                themeMode: themeMode,
                locale: appLocale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: [
                  ...AppLocalizations.localizationsDelegates,
                  LocaleNamesLocalizationsDelegate(),
                ],
                home: Builder(
                  builder:
                      (ctx) => Scaffold(
                        appBar: AppBar(
                          title: Text(AppLocalizations.of(ctx).appTitle),
                          actions: [
                            OutlinedButton.icon(
                              key: const Key('btn_appbar_settings'),
                              icon: const Icon(Icons.settings),
                              label: Text(AppLocalizations.of(ctx).settings),
                              onPressed:
                                  () => showDialog<bool>(
                                    context: ctx,
                                    builder: (_) => const SettingsDialog(),
                                  ),
                            ),
                          ],
                        ),
                        body: const _RootHomeSwitcher(),
                      ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RootHomeSwitcher extends ConsumerWidget {
  const _RootHomeSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdf = ref.watch(pdfProvider);
    if (!pdf.loaded) {
      return const WelcomeScreen();
    }
    return const PdfSignatureHomePage();
  }
}
