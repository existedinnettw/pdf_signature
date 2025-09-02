import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
import '../../../../data/services/preferences_providers.dart';

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  String? _theme;
  String? _language;
  // Page view removed; continuous-only

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(preferencesProvider);
    _theme = prefs.theme;
    _language = prefs.language;
    // pageView no longer configurable (continuous-only)
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.settings,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: l.close,
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(l.general, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(width: 140, child: Text('${l.language}:')),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ref
                        .watch(languageAutonymsProvider)
                        .when(
                          loading:
                              () => const SizedBox(
                                height: 48,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          error: (_, __) {
                            final items =
                                AppLocalizations.supportedLocales
                                    .map((loc) => toLanguageTag(loc))
                                    .toList()
                                  ..sort();
                            return DropdownButton<String>(
                              key: const Key('ddl_language'),
                              isExpanded: true,
                              value: _language,
                              items:
                                  items
                                      .map(
                                        (tag) => DropdownMenuItem(
                                          value: tag,
                                          child: Text(tag),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) => setState(() => _language = v),
                            );
                          },
                          data: (names) {
                            final items =
                                AppLocalizations.supportedLocales
                                    .map((loc) => toLanguageTag(loc))
                                    .toList()
                                  ..sort();
                            return DropdownButton<String>(
                              key: const Key('ddl_language'),
                              isExpanded: true,
                              value: _language,
                              items:
                                  items
                                      .map(
                                        (tag) => DropdownMenuItem<String>(
                                          value: tag,
                                          child: Text(names[tag] ?? tag),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) => setState(() => _language = v),
                            );
                          },
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(l.display, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(width: 140, child: Text('${l.theme}:')),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      key: const Key('ddl_theme'),
                      isExpanded: true,
                      value: _theme,
                      items: [
                        DropdownMenuItem(
                          value: 'light',
                          child: Text(l.themeLight),
                        ),
                        DropdownMenuItem(
                          value: 'dark',
                          child: Text(l.themeDark),
                        ),
                        DropdownMenuItem(
                          value: 'system',
                          child: Text(l.themeSystem),
                        ),
                      ],
                      onChanged: (v) => setState(() => _theme = v),
                    ),
                  ),
                ],
              ),
              // Page view setting removed (continuous-only)
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      final n = ref.read(preferencesProvider.notifier);
                      if (_theme != null) await n.setTheme(_theme!);
                      if (_language != null) await n.setLanguage(_language!);
                      // pageView not configurable anymore
                      if (mounted) Navigator.of(context).pop(true);
                    },
                    child: Text(l.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
