import 'package:file_selector/file_selector.dart' as fs;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/services/export_service.dart';

/// ViewModel for export-related UI state and helpers.
class PdfExportViewModel extends ChangeNotifier {
  final Ref ref;
  bool _exporting = false;

  // Dependencies (injectable via constructor for tests)
  final ExportService _exporter;
  final Future<String?> Function() _savePathPicker;

  PdfExportViewModel(
    this.ref, {
    ExportService? exporter,
    Future<String?> Function()? savePathPicker,
  }) : _exporter = exporter ?? ExportService(),
       _savePathPicker = savePathPicker ?? _defaultSavePathPicker;

  bool get exporting => _exporting;

  void setExporting(bool value) {
    if (_exporting == value) return;
    _exporting = value;
    notifyListeners();
  }

  /// Get the export service (overridable in tests via constructor).
  ExportService get exporter => _exporter;

  /// Show save dialog and return the chosen path (null if canceled).
  Future<String?> pickSavePath() async {
    return _savePathPicker();
  }

  static Future<String?> _defaultSavePathPicker() async {
    final group = fs.XTypeGroup(label: 'PDF', extensions: ['pdf']);
    final location = await fs.getSaveLocation(
      acceptedTypeGroups: [group],
      suggestedName: 'signed.pdf',
      confirmButtonText: 'Save',
    );
    return location?.path; // null if user cancels
  }
}

final pdfExportViewModelProvider = ChangeNotifierProvider<PdfExportViewModel>((
  ref,
) {
  return PdfExportViewModel(ref);
});
