import 'package:file_selector/file_selector.dart' as fs;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/services/export_service.dart';

/// Global exporting flag used to disable parts of the UI during long tasks.
final exportingProvider = StateProvider<bool>((ref) => false);

/// Provider for the export service. Can be overridden in tests.
final exportServiceProvider = Provider<ExportService>((ref) => ExportService());

/// Provider for a function that picks a save path. Tests may override.
final savePathPickerProvider = Provider<Future<String?> Function()>((ref) {
  return () async {
    // Desktop save dialog with PDF filter; mobile platforms may not support this.
    final group = fs.XTypeGroup(label: 'PDF', extensions: ['pdf']);
    final location = await fs.getSaveLocation(
      acceptedTypeGroups: [group],
      suggestedName: 'signed.pdf',
      confirmButtonText: 'Save',
    );
    return location?.path; // null if user cancels
  };
});
