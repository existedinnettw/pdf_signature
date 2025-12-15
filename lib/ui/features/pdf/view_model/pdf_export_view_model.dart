import 'dart:io' show Platform;
import 'package:file_picker/file_picker.dart' as fp;
import 'package:path_provider/path_provider.dart' as pp;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_export_state.dart';

/// ViewModel for export-related UI state and helpers.
class PdfExportViewModel extends Notifier<PdfExportState> {
  // Dependencies (injectable via constructor for tests)
  // Zero-arg picker retained for backward compatibility with tests.
  late final Future<String?> Function() _savePathPicker;
  // Preferred picker that accepts a suggested filename.
  late final Future<String?> Function(String suggestedName)
  _savePathPickerWithSuggestedName;

  @override
  PdfExportState build() {
    // Initialize with default pickers
    _savePathPicker = _defaultSavePathPicker;
    _savePathPickerWithSuggestedName = _defaultSavePathPickerWithSuggestedName;
    return PdfExportState.initial();
  }

  bool get exporting => state.exporting;

  void setExporting(bool value) {
    if (state.exporting == value) return;
    state = state.copyWith(exporting: value);
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
    // Prefer native save dialog via file_picker on all non-web platforms.
    // If the user cancels (null) simply bubble up null. If an exception occurs
    // (unsupported platform or plugin issue), fall back to an app documents path.
    try {
      final result = await fp.FilePicker.platform.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: suggestedName,
        type: fp.FileType.custom,
        allowedExtensions: const ['pdf'],
        // lockParentWindow is ignored on mobile; useful on desktop.
        lockParentWindow: true,
      );
      return result; // null if canceled
    } catch (_) {
      // Fall through to app documents fallback below.
    }

    debugPrint(
      'Fallback: select a folder and build path with suggested name (mobile platform)',
    );

    // On some mobile providers, saveFile may not present a picker or returns null.
    // Offer a folder picker and compose the final path.
    if (Platform.isAndroid || Platform.isIOS) {
      final dir = await fp.FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select folder to save',
        lockParentWindow: true,
      );
      if (dir != null && dir.trim().isNotEmpty) {
        final d = dir.trim();
        final needsSep = !(d.endsWith('/') || d.endsWith('\\'));
        return (needsSep ? (d + '/') : d) + suggestedName;
      }
      // User canceled directory selection; bubble up null.
      return null;
    }

    debugPrint('Fallback: build a default path (web platform)');
    try {
      final dir = await pp.getApplicationDocumentsDirectory();
      return '${dir.path}/$suggestedName';
    } catch (_) {
      // Last resort: let the caller handle a null path
      return null;
    }
  }
}

final pdfExportViewModelProvider =
    NotifierProvider<PdfExportViewModel, PdfExportState>(
      PdfExportViewModel.new,
    );
