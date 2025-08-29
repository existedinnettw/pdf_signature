import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
import '../providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.theme, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              key: const Key('ddl_theme'),
              value: prefs.theme,
              items: [
                DropdownMenuItem(value: 'light', child: Text(l.themeLight)),
                DropdownMenuItem(value: 'dark', child: Text(l.themeDark)),
                DropdownMenuItem(value: 'system', child: Text(l.themeSystem)),
              ],
              onChanged:
                  (v) =>
                      v == null
                          ? null
                          : ref.read(preferencesProvider.notifier).setTheme(v),
            ),
            const SizedBox(height: 16),
            Text(
              l.language,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              key: const Key('ddl_language'),
              value: prefs.language,
              items: [
                DropdownMenuItem(value: 'en', child: Text(l.languageEnglish)),
                DropdownMenuItem(
                  value: 'zh-TW',
                  child: Text(l.languageChineseTraditional),
                ),
                DropdownMenuItem(value: 'es', child: Text(l.languageSpanish)),
              ],
              onChanged:
                  (v) =>
                      v == null
                          ? null
                          : ref
                              .read(preferencesProvider.notifier)
                              .setLanguage(v),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: OutlinedButton(
                key: const Key('btn_reset_defaults'),
                onPressed:
                    () =>
                        ref
                            .read(preferencesProvider.notifier)
                            .resetToDefaults(),
                child: Text(l.resetToDefaults),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
