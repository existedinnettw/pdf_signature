import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
import 'package:pdf_signature/routing/router.dart';
import 'package:pdf_signature/ui/features/preferences/widgets/settings_screen.dart';
import 'data/repositories/preferences_repository.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          final prefs = ref.watch(preferencesRepositoryProvider);
          final seed = themeSeedFromPrefs(prefs);
          final appLocale =
              supportedLanguageTags().contains(prefs.language)
                  ? parseLanguageTag(prefs.language)
                  : null;
          final themeMode = () {
            switch (prefs.theme) {
              case 'light':
                return ThemeMode.light;
              case 'dark':
                return ThemeMode.dark;
              case 'system':
              default:
                return ThemeMode.system;
            }
          }();

          return MaterialApp.router(
            onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: seed,
                brightness: Brightness.light,
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: seed,
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
            routerConfig: ref.watch(routerProvider),
            builder: (context, child) {
              final router = ref.watch(routerProvider);
              return Scaffold(
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context).appTitle),
                  actions: [
                    OutlinedButton.icon(
                      key: const Key('btn_appbar_settings'),
                      icon: const Icon(Icons.settings),
                      label: Text(AppLocalizations.of(context).settings),
                      onPressed:
                          () => showDialog<bool>(
                            context:
                                router
                                    .routerDelegate
                                    .navigatorKey
                                    .currentContext!,
                            builder: (_) => const SettingsDialog(),
                          ),
                    ),
                  ],
                ),
                body: child,
              );
            },
          );
        },
      ),
    );
  }
}
