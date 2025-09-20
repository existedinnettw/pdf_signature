import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
import '../../../../data/repositories/preferences_repository.dart';

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  String? _theme;
  String? _language;
  // Page view removed; continuous-only
  double? _exportDpi;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(preferencesRepositoryProvider);
    _theme = prefs.theme;
    _language = prefs.language;
    _exportDpi = prefs.exportDpi;
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
                    child: FutureBuilder<Map<String, String>>(
                      future: languageAutonyms(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            height: 48,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final names = snapshot.data;
                        final tags =
                            AppLocalizations.supportedLocales
                                .map((loc) => toLanguageTag(loc))
                                .toList()
                              ..sort();
                        return DropdownButton<String>(
                          key: const Key('ddl_language'),
                          isExpanded: true,
                          value: _language,
                          items:
                              tags
                                  .map(
                                    (tag) => DropdownMenuItem<String>(
                                      value: tag,
                                      child: Text(names?[tag] ?? tag),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) async {
                            if (v == null) return;
                            setState(() => _language = v);
                            await ref
                                .read(preferencesRepositoryProvider.notifier)
                                .setLanguage(v);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  SizedBox(width: 140, child: Text('${l.dpi}:')),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<double>(
                      key: const Key('ddl_export_dpi'),
                      isExpanded: true,
                      value: _exportDpi,
                      items:
                          const [96.0, 144.0, 200.0, 300.0]
                              .map(
                                (v) => DropdownMenuItem<double>(
                                  value: v,
                                  child: Text(v.toStringAsFixed(0)),
                                ),
                              )
                              .toList(),
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() => _exportDpi = v);
                        await ref
                            .read(preferencesRepositoryProvider.notifier)
                            .setExportDpi(v);
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
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() => _theme = v);
                        await ref
                            .read(preferencesRepositoryProvider.notifier)
                            .setTheme(v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(width: 140, child: Text('${l.themeColor}:')),
                  const SizedBox(width: 8),
                  _ThemeColorCircle(
                    onPick: (value) async {
                      if (value == null) return;
                      await ref
                          .read(preferencesRepositoryProvider.notifier)
                          .setThemeColor(value);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final double size;
  const _ColorDot({required this.color, this.size = 14});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
  );
}

class _ThemeColorCircle extends ConsumerWidget {
  final ValueChanged<String?> onPick;
  const _ThemeColorCircle({required this.onPick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seed = themeSeedFromPrefs(ref.watch(preferencesRepositoryProvider));
    return InkWell(
      key: const Key('btn_theme_color_picker'),
      onTap: () async {
        final picked = await showDialog<String>(
          context: context,
          builder: (ctx) => _ThemeColorPickerDialog(currentColor: seed),
        );
        onPick(picked);
      },
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: _ColorDot(color: seed, size: 22),
      ),
    );
  }
}

class _ThemeColorPickerDialog extends StatelessWidget {
  final Color currentColor;
  const _ThemeColorPickerDialog({required this.currentColor});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.themeColor),
      content: SizedBox(
        width: 320,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              Colors.primaries.map((mat) {
                final Color c = mat; // MaterialColor is a Color
                final selected = c == currentColor;
                // Store as ARGB hex string, e.g., #FF2196F3
                String hex(Color color) {
                  final a =
                      ((color.a * 255.0).round() & 0xff)
                          .toRadixString(16)
                          .padLeft(2, '0')
                          .toUpperCase();
                  final r =
                      ((color.r * 255.0).round() & 0xff)
                          .toRadixString(16)
                          .padLeft(2, '0')
                          .toUpperCase();
                  final g =
                      ((color.g * 255.0).round() & 0xff)
                          .toRadixString(16)
                          .padLeft(2, '0')
                          .toUpperCase();
                  final b =
                      ((color.b * 255.0).round() & 0xff)
                          .toRadixString(16)
                          .padLeft(2, '0')
                          .toUpperCase();
                  return '#$a$r$g$b';
                }

                return InkWell(
                  key: Key('pick_${hex(c)}'),
                  onTap: () => Navigator.of(context).pop(hex(c)),
                  customBorder: const CircleBorder(),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _ColorDot(color: c, size: 32),
                      if (selected)
                        const Icon(Icons.check, color: Colors.white, size: 20),
                    ],
                  ),
                );
              }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l.cancel),
        ),
      ],
    );
  }
}
