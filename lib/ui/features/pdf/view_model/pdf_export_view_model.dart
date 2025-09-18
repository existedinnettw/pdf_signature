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
  // Zero-arg picker retained for backward compatibility with tests.
  final Future<String?> Function() _savePathPicker;
  // Preferred picker that accepts a suggested filename.
  final Future<String?> Function(String suggestedName)
  _savePathPickerWithSuggestedName;

  PdfExportViewModel(
    this.ref, {
    ExportService? exporter,
    Future<String?> Function()? savePathPicker,
    Future<String?> Function(String suggestedName)?
    savePathPickerWithSuggestedName,
  }) : _exporter = exporter ?? ExportService(),
       _savePathPicker = savePathPicker ?? _defaultSavePathPicker,
       // Prefer provided suggested-name picker; otherwise, if only zero-arg
       // picker is given (tests), wrap it; else use default that honors name.
       _savePathPickerWithSuggestedName =
           savePathPickerWithSuggestedName ??
           (savePathPicker != null
               ? ((_) => savePathPicker())
               : _defaultSavePathPickerWithSuggestedName);

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

  /// Show save dialog with a suggested name and return the chosen path.
  Future<String?> pickSavePathWithSuggestedName(String suggestedName) async {
    return _savePathPickerWithSuggestedName(suggestedName);
  }

  static Future<String?> _defaultSavePathPicker() async {
    return _defaultSavePathPickerWithSuggestedName('signed.pdf');
  }

  static Future<String?> _defaultSavePathPickerWithSuggestedName(
    String suggestedName,
  ) async {
    final group = fs.XTypeGroup(label: 'PDF', extensions: ['pdf']);
    final location = await fs.getSaveLocation(
      acceptedTypeGroups: [group],
      suggestedName: suggestedName,
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
