import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/services/export_service.dart';

/// Global exporting flag used to disable parts of the UI during long tasks.
final exportingProvider = StateProvider<bool>((ref) => false);

/// Provider for the export service. Can be overridden in tests.
final exportServiceProvider = Provider<ExportService>((ref) => ExportService());

/// Provider for a function that picks a save path. Tests may override.
final savePathPickerProvider = Provider<Future<String?> Function()>((ref) {
  return () async => null;
});
