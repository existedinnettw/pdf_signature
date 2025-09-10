import 'dart:typed_data';
import 'signature_placement.dart';

/// PDF document to be signed
class Document {
  final bool loaded;
  final int pageCount;
  final int currentPage;
  final Uint8List? pickedPdfBytes;
  // Multiple signature placements per page, each combines geometry and asset.
  final Map<int, List<SignaturePlacement>> placementsByPage;
  const Document({
    required this.loaded,
    required this.pageCount,
    required this.currentPage,
    this.pickedPdfBytes,
    this.placementsByPage = const {},
  });
  factory Document.initial() => const Document(
    loaded: false,
    pageCount: 0,
    currentPage: 1,
    pickedPdfBytes: null,
    placementsByPage: {},
  );
  Document copyWith({
    bool? loaded,
    int? pageCount,
    int? currentPage,
    Uint8List? pickedPdfBytes,
    Map<int, List<SignaturePlacement>>? placementsByPage,
  }) => Document(
    loaded: loaded ?? this.loaded,
    pageCount: pageCount ?? this.pageCount,
    currentPage: currentPage ?? this.currentPage,
    pickedPdfBytes: pickedPdfBytes ?? this.pickedPdfBytes,
    placementsByPage: placementsByPage ?? this.placementsByPage,
  );
}
