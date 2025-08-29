import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/pdf_screen.dart';
import 'ui/features/preferences/providers.dart';

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
                  home: Scaffold(body: Center(child: Text('Error: $e'))),
                ),
            data: (_) {
              final themeMode = ref.watch(themeModeProvider);
              final appLocale = ref.watch(localeProvider);
              return MaterialApp(
                title: 'PDF Signature',
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
                supportedLocales: supportedLocales,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: const PdfSignatureHomePage(),
              );
            },
          );
        },
      ),
    );
  }
}
