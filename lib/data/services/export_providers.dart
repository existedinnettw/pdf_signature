import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart' as pp;
import 'package:file_selector/file_selector.dart' as fs;
import 'package:pdf_signature/data/services/export_service.dart';
import 'package:pdf_signature/data/services/preferences_providers.dart';

// Feature-scoped DI and configuration providers

// Toggle mock viewer (used by tests to show a gray placeholder instead of real PDF pages)
final useMockViewerProvider = Provider<bool>((_) => false);

// Export service injection for testability
final exportServiceProvider = Provider<ExportService>((_) => ExportService());

// Export DPI setting (points per inch mapping). Reads from SharedPreferences when available,
// otherwise falls back to 144.0 to keep tests deterministic without bootstrapping prefs.
final exportDpiProvider = Provider<double>((ref) {
  final sp = ref.watch(sharedPreferencesProvider);
  return sp.maybeWhen(
    data: (prefs) {
      const allowed = [96.0, 144.0, 200.0, 300.0];
      final v = prefs.getDouble('export_dpi');
      return (v != null && allowed.contains(v)) ? v : 144.0;
    },
    orElse: () => 144.0,
  );
});

// Controls whether signature overlay is visible (used to hide on non-stamped pages during export)
final signatureVisibilityProvider = StateProvider<bool>((_) => true);

// Global exporting state to show loading UI and block interactions while saving/exporting
final exportingProvider = StateProvider<bool>((_) => false);

// Save path picker (injected for tests)
final savePathPickerProvider = Provider<Future<String?> Function()>((ref) {
  return () async {
    String? initialDir;
    try {
      final d = await pp.getDownloadsDirectory();
      initialDir = d?.path;
    } catch (_) {}
    if (initialDir == null) {
      try {
        final d = await pp.getApplicationDocumentsDirectory();
        initialDir = d.path;
      } catch (_) {}
    }
    final location = await fs.getSaveLocation(
      suggestedName: 'signed.pdf',
      acceptedTypeGroups: [
        const fs.XTypeGroup(label: 'PDF', extensions: ['pdf']),
      ],
      initialDirectory: initialDir,
    );
    if (location == null) return null;
    final path = location.path;
    return path.toLowerCase().endsWith('.pdf') ? path : '$path.pdf';
  };
});
