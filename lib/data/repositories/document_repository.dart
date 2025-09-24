import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/services/export_service.dart';

import '../../domain/models/model.dart';

class DocumentStateNotifier extends StateNotifier<Document> {
  DocumentStateNotifier({ExportService? service})
    : _service = service ?? ExportService(),
      super(Document.initial());

  final ExportService _service;

  @visibleForTesting
  void openSample() {
    state = state.copyWith(
      loaded: true,
      pageCount: 5,
      pickedPdfBytes: null,
      placementsByPage: <int, List<SignaturePlacement>>{},
    );
  }

  void openPicked({required int pageCount, Uint8List? bytes}) {
    state = state.copyWith(
      loaded: true,
      pageCount: pageCount,
      pickedPdfBytes: bytes,
      placementsByPage: <int, List<SignaturePlacement>>{},
    );
  }

  void close() {
    state = Document.initial();
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
        asset: asset ?? SignatureAsset(sigImage: _singleTransparentPng),
        rotationDeg: rotationDeg,
        graphicAdjust: graphicAdjust ?? const GraphicAdjust(),
      ),
    );
    map[p] = list;
    state = state.copyWith(placementsByPage: map);
  }

  // Tiny 1x1 transparent PNG to avoid decode crashes in tests when no real
  // signature bytes were provided.
  static final img.Image _singleTransparentPng = img.Image(width: 1, height: 1);

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

  Future<bool> exportDocument({
    required String outputPath,
    required Size uiPageSize,
    required Uint8List? signatureImageBytes,
    double targetDpi = 144.0,
  }) async {
    final bytes = await exportDocumentToBytes(
      uiPageSize: uiPageSize,
      signatureImageBytes: signatureImageBytes,
      targetDpi: targetDpi,
    );

    Future<void> _ = Future<void>.delayed(Duration.zero);

    if (bytes == null) return false;
    final ok = await _service.saveBytesToFile(
      bytes: bytes,
      outputPath: outputPath,
    );
    return ok;
  }

  Future<Uint8List?> exportDocumentToBytes({
    required Size uiPageSize,
    required Uint8List? signatureImageBytes,
    double targetDpi = 144.0,
  }) async {
    if (!state.loaded || state.pickedPdfBytes == null) return null;
    // Experimental: run export in a background isolate using `compute`.
    // We serialize placements and signature assets to isolate-safe data.
    try {
      final args = _buildIsolateArgs(
        srcBytes: state.pickedPdfBytes!,
        uiPageSize: uiPageSize,
        signatureImageBytes: signatureImageBytes,
        placementsByPage: state.placementsByPage,
        targetDpi: targetDpi,
      );
      final result = await compute<_ExportIsolateArgs, Uint8List?>(
        _exportInIsolate,
        args,
      );
      if (result != null) return result;
    } catch (_) {
      debugPrint('Warning: export in isolate failed');
      // Fall back to main-isolate export if isolate fails (e.g., engine limitations).
    }

    // Fallback on main isolate
    return await _service.exportSignedPdfFromBytes(
      srcBytes: state.pickedPdfBytes!,
      uiPageSize: uiPageSize,
      signatureImageBytes: signatureImageBytes,
      placementsByPage: state.placementsByPage,
      targetDpi: targetDpi,
    );
  }
}

final documentRepositoryProvider =
    StateNotifierProvider<DocumentStateNotifier, Document>(
      (ref) => DocumentStateNotifier(),
    );

/// --- Isolate helpers of DocumentRepository ---
/// Following are helpers to transfer data to/from an isolate for export.

class _ExportIsolateArgs {
  final TransferableTypedData src;
  final double pageW;
  final double pageH;
  final double targetDpi;
  final List<_IsoPagePlacements> pages;
  final TransferableTypedData? signatureImageBytes; // not used currently
  _ExportIsolateArgs({
    required this.src,
    required this.pageW,
    required this.pageH,
    required this.targetDpi,
    required this.pages,
    required this.signatureImageBytes,
  });
}

class _IsoPagePlacements {
  final int page;
  final List<_IsoPlacement> items;
  _IsoPagePlacements(this.page, this.items);
}

class _IsoPlacement {
  final double l, t, w, h;
  final double rot;
  final double contrast, brightness;
  final bool bgRemoval;
  final TransferableTypedData assetPng;
  _IsoPlacement({
    required this.l,
    required this.t,
    required this.w,
    required this.h,
    required this.rot,
    required this.contrast,
    required this.brightness,
    required this.bgRemoval,
    required this.assetPng,
  });
}

_ExportIsolateArgs _buildIsolateArgs({
  required Uint8List srcBytes,
  required Size uiPageSize,
  required Uint8List? signatureImageBytes,
  required Map<int, List<SignaturePlacement>> placementsByPage,
  required double targetDpi,
}) {
  final pages = <_IsoPagePlacements>[];
  placementsByPage.forEach((page, items) {
    final isoItems = <_IsoPlacement>[];
    for (final p in items) {
      // Encode the asset image to PNG for transfer; small count expected.
      final png = Uint8List.fromList(img.encodePng(p.asset.sigImage, level: 3));
      isoItems.add(
        _IsoPlacement(
          l: p.rect.left,
          t: p.rect.top,
          w: p.rect.width,
          h: p.rect.height,
          rot: p.rotationDeg,
          contrast: p.graphicAdjust.contrast,
          brightness: p.graphicAdjust.brightness,
          bgRemoval: p.graphicAdjust.bgRemoval,
          assetPng: TransferableTypedData.fromList([png]),
        ),
      );
    }
    pages.add(_IsoPagePlacements(page, isoItems));
  });
  return _ExportIsolateArgs(
    src: TransferableTypedData.fromList([srcBytes]),
    pageW: uiPageSize.width,
    pageH: uiPageSize.height,
    targetDpi: targetDpi,
    pages: pages,
    signatureImageBytes:
        signatureImageBytes == null
            ? null
            : TransferableTypedData.fromList([signatureImageBytes]),
  );
}

Future<Uint8List?> _exportInIsolate(_ExportIsolateArgs args) async {
  // Rebuild placements
  final placementsByPage = <int, List<SignaturePlacement>>{};
  for (final page in args.pages) {
    final list = <SignaturePlacement>[];
    for (final it in page.items) {
      final bytes = it.assetPng.materialize().asUint8List();
      final decoded = img.decodePng(bytes);
      if (decoded == null) continue;
      final asset = SignatureAsset(sigImage: decoded);
      list.add(
        SignaturePlacement(
          rect: Rect.fromLTWH(it.l, it.t, it.w, it.h),
          asset: asset,
          rotationDeg: it.rot,
          graphicAdjust: GraphicAdjust(
            contrast: it.contrast,
            brightness: it.brightness,
            bgRemoval: it.bgRemoval,
          ),
        ),
      );
    }
    if (list.isNotEmpty) {
      placementsByPage[page.page] = list;
    }
  }

  final src = args.src.materialize().asUint8List();
  final service = ExportService();
  return await service.exportSignedPdfFromBytes(
    srcBytes: src,
    uiPageSize: Size(args.pageW, args.pageH),
    signatureImageBytes: args.signatureImageBytes?.materialize().asUint8List(),
    placementsByPage: placementsByPage,
    targetDpi: args.targetDpi,
  );
}
