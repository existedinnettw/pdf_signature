import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/model/model.dart';

class PdfController extends StateNotifier<PdfState> {
  PdfController() : super(PdfState.initial());
  static const int samplePageCount = 5;

  @visibleForTesting
  void openSample() {
    state = state.copyWith(
      loaded: true,
      pageCount: samplePageCount,
      currentPage: 1,
      pickedPdfPath: null,
      signedPage: null,
      placementsByPage: {},
      placementImageByPage: {},
      selectedPlacementIndex: null,
    );
  }

  void openPicked({
    required String path,
    int pageCount = samplePageCount,
    Uint8List? bytes,
  }) {
    state = state.copyWith(
      loaded: true,
      pageCount: pageCount,
      currentPage: 1,
      pickedPdfPath: path,
      pickedPdfBytes: bytes,
      signedPage: null,
      placementsByPage: {},
      placementImageByPage: {},
      selectedPlacementIndex: null,
    );
  }

  void jumpTo(int page) {
    if (!state.loaded) return;
    final clamped = page.clamp(1, state.pageCount);
    state = state.copyWith(currentPage: clamped, selectedPlacementIndex: null);
  }

  // Set or clear the page that will receive the signature overlay.
  void setSignedPage(int? page) {
    if (!state.loaded) return;
    if (page == null) {
      state = state.copyWith(signedPage: null, selectedPlacementIndex: null);
    } else {
      final clamped = page.clamp(1, state.pageCount);
      state = state.copyWith(signedPage: clamped, selectedPlacementIndex: null);
    }
  }

  void setPageCount(int count) {
    if (!state.loaded) return;
    state = state.copyWith(pageCount: count.clamp(1, 9999));
  }

  // Multiple-signature helpers (rects are stored in normalized fractions 0..1
  // relative to the page size: left/top/width/height are all 0..1)
  void addPlacement({
    required int page,
    required Rect rect,
    String image = 'default.png',
  }) {
    if (!state.loaded) return;
    final p = page.clamp(1, state.pageCount);
    final map = Map<int, List<Rect>>.from(state.placementsByPage);
    final list = List<Rect>.from(map[p] ?? const []);
    list.add(rect);
    map[p] = list;
    // Sync image mapping list
    final imgMap = Map<int, List<String>>.from(state.placementImageByPage);
    final imgList = List<String>.from(imgMap[p] ?? const []);
    imgList.add(image);
    imgMap[p] = imgList;
    state = state.copyWith(
      placementsByPage: map,
      placementImageByPage: imgMap,
      selectedPlacementIndex: null,
    );
  }

  void removePlacement({required int page, required int index}) {
    if (!state.loaded) return;
    final p = page.clamp(1, state.pageCount);
    final map = Map<int, List<Rect>>.from(state.placementsByPage);
    final list = List<Rect>.from(map[p] ?? const []);
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      // Sync image mapping
      final imgMap = Map<int, List<String>>.from(state.placementImageByPage);
      final imgList = List<String>.from(imgMap[p] ?? const []);
      if (index >= 0 && index < imgList.length) {
        imgList.removeAt(index);
      }
      if (list.isEmpty) {
        map.remove(p);
        imgMap.remove(p);
      } else {
        map[p] = list;
        imgMap[p] = imgList;
      }
      state = state.copyWith(
        placementsByPage: map,
        placementImageByPage: imgMap,
        selectedPlacementIndex: null,
      );
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
    final map = Map<int, List<Rect>>.from(state.placementsByPage);
    final list = List<Rect>.from(map[p] ?? const []);
    if (index >= 0 && index < list.length) {
      list[index] = rect;
      map[p] = list;
      state = state.copyWith(placementsByPage: map);
    }
  }

  List<Rect> placementsOn(int page) {
    return List<Rect>.from(state.placementsByPage[page] ?? const []);
  }

  void selectPlacement(int? index) {
    if (!state.loaded) return;
    // Only allow valid index on current page; otherwise clear
    if (index == null) {
      state = state.copyWith(selectedPlacementIndex: null);
      return;
    }
    final list = state.placementsByPage[state.currentPage] ?? const [];
    if (index >= 0 && index < list.length) {
      state = state.copyWith(selectedPlacementIndex: index);
    } else {
      state = state.copyWith(selectedPlacementIndex: null);
    }
  }

  void deleteSelectedPlacement() {
    final idx = state.selectedPlacementIndex;
    if (idx == null) return;
    removePlacement(page: state.currentPage, index: idx);
  }

  // NOTE: Programmatic reassignment of images has been removed.

  // Convenience to get image name for a placement
  String? imageOfPlacement({required int page, required int index}) {
    final list = state.placementImageByPage[page] ?? const [];
    if (index < 0 || index >= list.length) return null;
    return list[index];
  }
}

final pdfProvider = StateNotifierProvider<PdfController, PdfState>(
  (ref) => PdfController(),
);
