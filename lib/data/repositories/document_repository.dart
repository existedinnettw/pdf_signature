import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/services/export_service.dart';

import '../../domain/models/model.dart';

class DocumentStateNotifier extends StateNotifier<Document> {
  DocumentStateNotifier() : super(Document.initial());

  final ExportService _service = ExportService();

  @visibleForTesting
  void openSample() {
    state = state.copyWith(loaded: true, pageCount: 5, placementsByPage: {});
  }

  void openPicked({
    required String path,
    required int pageCount,
    Uint8List? bytes,
  }) {
    state = state.copyWith(
      loaded: true,
      pageCount: pageCount,
      pickedPdfBytes: bytes,
      placementsByPage: {},
    );
  }

  void setPageCount(int count) {
    if (!state.loaded) return;
    state = state.copyWith(pageCount: count.clamp(1, 9999));
  }

  void jumpTo(int page) {
    // currentPage is now in view model, so jumpTo does nothing here
  }

  // Multiple-signature helpers (rects are stored in normalized fractions 0..1
  // relative to the page size: left/top/width/height are all 0..1)
  void addPlacement({
    required int page,
    required Rect rect,
    SignatureAsset? asset,
    double rotationDeg = 0.0,
    GraphicAdjust? graphicAdjust,
  }) {
    if (!state.loaded) return;
    final p = page.clamp(1, state.pageCount);
    final map = Map<int, List<SignaturePlacement>>.from(state.placementsByPage);
    final list = List<SignaturePlacement>.from(map[p] ?? const []);
    list.add(
      SignaturePlacement(
        rect: rect,
        asset: asset ?? SignatureAsset(bytes: Uint8List(0)),
        rotationDeg: rotationDeg,
        graphicAdjust: graphicAdjust ?? const GraphicAdjust(),
      ),
    );
    map[p] = list;
    state = state.copyWith(placementsByPage: map);
  }

  void updatePlacementRotation({
    required int page,
    required int index,
    required double rotationDeg,
  }) {
    if (!state.loaded) return;
    final p = page.clamp(1, state.pageCount);
    final map = Map<int, List<SignaturePlacement>>.from(state.placementsByPage);
    final list = List<SignaturePlacement>.from(map[p] ?? const []);
    if (index >= 0 && index < list.length) {
      list[index] = list[index].copyWith(rotationDeg: rotationDeg);
      map[p] = list;
      state = state.copyWith(placementsByPage: map);
    }
  }

  void removePlacement({required int page, required int index}) {
    if (!state.loaded) return;
    final p = page.clamp(1, state.pageCount);
    final map = Map<int, List<SignaturePlacement>>.from(state.placementsByPage);
    final list = List<SignaturePlacement>.from(map[p] ?? const []);
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      if (list.isEmpty) {
        map.remove(p);
      } else {
        map[p] = list;
      }
      state = state.copyWith(placementsByPage: map);
    }
  }

  // Update the rect of an existing placement on a page.
  void updatePlacementRect({
    required int page,
    required int index,
    required Rect rect,
  }) {
    if (!state.loaded) return;
    final p = page.clamp(1, state.pageCount);
    final map = Map<int, List<SignaturePlacement>>.from(state.placementsByPage);
    final list = List<SignaturePlacement>.from(map[p] ?? const []);
    if (index >= 0 && index < list.length) {
      final existing = list[index];
      list[index] = existing.copyWith(rect: rect);
      map[p] = list;
      state = state.copyWith(placementsByPage: map);
    }
  }

  List<SignaturePlacement> placementsOn(int page) {
    return List<SignaturePlacement>.from(
      state.placementsByPage[page] ?? const [],
    );
  }

  // Convenience to get asset for a placement
  SignatureAsset? assetOfPlacement({required int page, required int index}) {
    final list = state.placementsByPage[page] ?? const [];
    if (index < 0 || index >= list.length) return null;
    return list[index].asset;
  }

  Future<void> exportDocument({
    required String outputPath,
    required Size uiPageSize,
    required Uint8List? signatureImageBytes,
  }) async {
    if (!state.loaded || state.pickedPdfBytes == null) return;
    final bytes = await _service.exportSignedPdfFromBytes(
      srcBytes: state.pickedPdfBytes!,
      uiPageSize: uiPageSize,
      signatureImageBytes: signatureImageBytes,
      placementsByPage: state.placementsByPage,
    );
    if (bytes == null) return;
    _service.saveBytesToFile(bytes: bytes, outputPath: outputPath);
    // await
  }
}

final documentRepositoryProvider =
    StateNotifierProvider<DocumentStateNotifier, Document>(
      (ref) => DocumentStateNotifier(),
    );
