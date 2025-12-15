import 'package:cross_file/cross_file.dart';

/// Immutable state for PdfSessionViewModel
class PdfSessionState {
  final XFile currentFile;
  final String displayFileName;

  const PdfSessionState({
    required this.currentFile,
    required this.displayFileName,
  });

  factory PdfSessionState.initial() {
    return PdfSessionState(currentFile: XFile(''), displayFileName: '');
  }

  PdfSessionState copyWith({XFile? currentFile, String? displayFileName}) {
    return PdfSessionState(
      currentFile: currentFile ?? this.currentFile,
      displayFileName: displayFileName ?? this.displayFileName,
    );
  }
}
