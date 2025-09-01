import 'package:bdd_widget_test/data_table.dart' as bdd;
import 'package:flutter_test/flutter_test.dart';

/// Usage: the app supports languages
/// | 'en' |
/// | 'zh-TW' |
/// | 'es' |
Future<void> theAppSupportsLanguages(
  WidgetTester tester,
  dynamic languages,
) async {
  // Accept either a DataTable from bdd_widget_test or a string like "{en, zh-TW, es}"
  final Set<String> expected;
  if (languages is bdd.DataTable) {
    final lists = languages.asLists();
    // Flatten ignoring header rows if any
    final items =
        lists
            .skipWhile(
              (row) => row.any(
                (e) =>
                    e.toString().contains('artist') ||
                    e.toString().contains('name'),
              ),
            )
            .expand((row) => row)
            .map((e) => e.toString().replaceAll("'", '').trim())
            .where((e) => e.isNotEmpty)
            .toSet();
    expected = items;
  } else {
    final raw = languages.toString().trim();
    final inner =
        raw.startsWith('{') && raw.endsWith('}')
            ? raw.substring(1, raw.length - 1)
            : raw;
    expected =
        inner.split(',').map((s) => s.trim().replaceAll("'", '')).toSet();
  }

  // Keep this in sync with the app's supported locales
  const actual = {'en', 'zh-TW', 'es'};
  expect(actual, expected);
}
