import 'dart:io' show Platform;
import 'package:file_picker/file_picker.dart' as fp;
import 'package:path_provider/path_provider.dart' as pp;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';

/// ViewModel for export-related UI state and helpers.
class PdfExportViewModel extends ChangeNotifier {
  final Ref ref;
  bool _exporting = false;

  // Dependencies (injectable via constructor for tests)
  // Zero-arg picker retained for backward compatibility with tests.
  final Future<String?> Function() _savePathPicker;
  // Preferred picker that accepts a suggested filename.
  final Future<String?> Function(String suggestedName)
  _savePathPickerWithSuggestedName;

  PdfExportViewModel(
    this.ref, {
    Future<String?> Function()? savePathPicker,
    Future<String?> Function(String suggestedName)?
    savePathPickerWithSuggestedName,
  }) : _savePathPicker = savePathPicker ?? _defaultSavePathPicker,
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

  /// Perform export via document repository. Returns true on success.
  Future<bool> exportToPath({
    required String outputPath,
    required Size uiPageSize,
    required Uint8List? signatureImageBytes,
    double targetDpi = 144.0,
  }) async {
    return await ref
        .read(documentRepositoryProvider.notifier)
        .exportDocument(
          outputPath: outputPath,
          uiPageSize: uiPageSize,
          signatureImageBytes: signatureImageBytes,
          targetDpi: targetDpi,
        );
  }

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
    // Desktop/web platforms: show save dialog via file_picker
    // Mobile (Android/iOS): fall back to app-writable directory with suggested name
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final result = await fp.FilePicker.platform.saveFile(
          dialogTitle: 'Save as',
          fileName: suggestedName,
          type: fp.FileType.custom,
          allowedExtensions: const ['pdf'],
          lockParentWindow: true,
        );
        return result; // null if canceled
      }
    } catch (_) {
      // Platform not available (e.g., web) falls through to default
    }

    // Mobile or unsupported platform: build a default path in app documents
    try {
      final dir = await pp.getApplicationDocumentsDirectory();
      return '${dir.path}/$suggestedName';
    } catch (_) {
      // Last resort: let the caller handle a null path
      return null;
    }
  }
}

final pdfExportViewModelProvider = ChangeNotifierProvider<PdfExportViewModel>((
  ref,
) {
  return PdfExportViewModel(ref);
});
