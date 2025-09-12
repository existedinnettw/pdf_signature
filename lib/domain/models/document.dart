import 'dart:typed_data';
import 'signature_placement.dart';

/// PDF document to be signed
class Document {
  bool loaded;
  int pageCount;
  Uint8List? pickedPdfBytes;
  // Multiple signature placements per page, each combines geometry and asset.
  Map<int, List<SignaturePlacement>> placementsByPage;

  Document({
    required this.loaded,
    required this.pageCount,
    this.pickedPdfBytes,
    Map<int, List<SignaturePlacement>>? placementsByPage,
  }) : placementsByPage = placementsByPage ?? <int, List<SignaturePlacement>>{};

  factory Document.initial() => Document(
    loaded: false,
    pageCount: 0,
    pickedPdfBytes: null,
    placementsByPage: <int, List<SignaturePlacement>>{},
  );

  Document copyWith({
    bool? loaded,
    int? pageCount,
    Uint8List? pickedPdfBytes,
    Map<int, List<SignaturePlacement>>? placementsByPage,
  }) => Document(
    loaded: loaded ?? this.loaded,
    pageCount: pageCount ?? this.pageCount,
    pickedPdfBytes: pickedPdfBytes ?? this.pickedPdfBytes,
    placementsByPage: placementsByPage ?? this.placementsByPage,
  );
}
