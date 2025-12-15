/// Immutable state for PdfExportViewModel
class PdfExportState {
  final bool exporting;

  const PdfExportState({required this.exporting});

  factory PdfExportState.initial() {
    return const PdfExportState(exporting: false);
  }

  PdfExportState copyWith({bool? exporting}) {
    return PdfExportState(exporting: exporting ?? this.exporting);
  }
}
