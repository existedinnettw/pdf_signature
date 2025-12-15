import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:pdf_signature/ui/features/pdf/view_model/document_version.dart';
import 'package:pdfrx/pdfrx.dart';

/// Immutable state for PdfViewModel
class PdfViewState {
  final PdfViewerController controller;
  final int currentPage;
  final bool useMockViewer;
  final Rect? activeRect;
  final Set<String> lockedPlacements;
  final DocumentVersion documentVersion;

  const PdfViewState({
    required this.controller,
    required this.currentPage,
    required this.useMockViewer,
    this.activeRect,
    required this.lockedPlacements,
    required this.documentVersion,
  });

  factory PdfViewState.initial({bool? useMockViewer}) {
    // Default to false (no mocking) - tests should explicitly pass true if they want mock viewer
    final defaultUseMock = useMockViewer ?? false;
    return PdfViewState(
      controller: PdfViewerController(),
      currentPage: 1,
      useMockViewer: defaultUseMock,
      activeRect: null,
      lockedPlacements: const {},
      documentVersion: DocumentVersion.initial(),
    );
  }

  PdfViewState copyWith({
    PdfViewerController? controller,
    int? currentPage,
    bool? useMockViewer,
    Rect? activeRect,
    bool clearActiveRect = false,
    Set<String>? lockedPlacements,
    DocumentVersion? documentVersion,
  }) {
    return PdfViewState(
      controller: controller ?? this.controller,
      currentPage: currentPage ?? this.currentPage,
      useMockViewer: useMockViewer ?? this.useMockViewer,
      activeRect: clearActiveRect ? null : (activeRect ?? this.activeRect),
      lockedPlacements: lockedPlacements ?? this.lockedPlacements,
      documentVersion: documentVersion ?? this.documentVersion,
    );
  }
}
