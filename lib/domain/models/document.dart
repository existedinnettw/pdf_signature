import 'dart:typed_data';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'signature_placement.dart';

part 'document.freezed.dart';

/// PDF document to be signed
@freezed
abstract class Document with _$Document {
  const factory Document({
    @Default(false) bool loaded,
    @Default(0) int pageCount,
    Uint8List? pickedPdfBytes,
    @Default(<int, List<SignaturePlacement>>{})
    Map<int, List<SignaturePlacement>> placementsByPage,
  }) = _Document;

  factory Document.initial() => const Document();
}
