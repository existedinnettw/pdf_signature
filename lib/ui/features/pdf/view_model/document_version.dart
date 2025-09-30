import 'dart:typed_data';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_version.freezed.dart';

/// Internal data model for tracking document versions in the UI layer.
/// This is separate from the domain Document model to avoid coupling UI concerns with business logic.
@freezed
abstract class DocumentVersion with _$DocumentVersion {
  const factory DocumentVersion({
    @Default(0) int version,
    Uint8List? lastBytes,
  }) = _DocumentVersion;

  factory DocumentVersion.initial() => const DocumentVersion();
}

extension DocumentVersionMethods on DocumentVersion {
  /// Generate the source name for PdfDocumentRefData based on version
  String get sourceName => 'document_v$version.pdf';

  /// Check if bytes have changed and need version increment
  bool shouldIncrementVersion(Uint8List? newBytes) {
    return !identical(lastBytes, newBytes);
  }

  /// Increment version and update bytes
  DocumentVersion incrementVersion(Uint8List? newBytes) {
    return copyWith(version: version + 1, lastBytes: newBytes);
  }
}
