import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Theme', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              key: const Key('ddl_theme'),
              value: prefs.theme,
              items: const [
                DropdownMenuItem(value: 'light', child: Text('Light')),
                DropdownMenuItem(value: 'dark', child: Text('Dark')),
                DropdownMenuItem(value: 'system', child: Text('System')),
              ],
              onChanged:
                  (v) =>
                      v == null
                          ? null
                          : ref.read(preferencesProvider.notifier).setTheme(v),
            ),
            const SizedBox(height: 16),
            const Text(
              'Language',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              key: const Key('ddl_language'),
              value: prefs.language,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'zh-TW', child: Text('繁體中文')),
                DropdownMenuItem(value: 'es', child: Text('Español')),
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
                child: const Text('Reset to defaults'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
