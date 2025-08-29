import 'dart:typed_data';
import 'package:flutter/widgets.dart';

class PdfState {
  final bool loaded;
  final int pageCount;
  final int currentPage;
  final String? pickedPdfPath;
  final Uint8List? pickedPdfBytes;
  final int? signedPage;
  const PdfState({
    required this.loaded,
    required this.pageCount,
    required this.currentPage,
    this.pickedPdfPath,
    this.pickedPdfBytes,
    this.signedPage,
  });
  factory PdfState.initial() => const PdfState(
    loaded: false,
    pageCount: 0,
    currentPage: 1,
    pickedPdfBytes: null,
    signedPage: null,
  );
  PdfState copyWith({
    bool? loaded,
    int? pageCount,
    int? currentPage,
    String? pickedPdfPath,
    Uint8List? pickedPdfBytes,
    int? signedPage,
  }) => PdfState(
    loaded: loaded ?? this.loaded,
    pageCount: pageCount ?? this.pageCount,
    currentPage: currentPage ?? this.currentPage,
    pickedPdfPath: pickedPdfPath ?? this.pickedPdfPath,
    pickedPdfBytes: pickedPdfBytes ?? this.pickedPdfBytes,
    signedPage: signedPage ?? this.signedPage,
  );
}

class SignatureState {
  final Rect? rect;
  final bool aspectLocked;
  final bool bgRemoval;
  final double contrast;
  final double brightness;
  final List<List<Offset>> strokes;
  final Uint8List? imageBytes;
  const SignatureState({
    required this.rect,
    required this.aspectLocked,
    required this.bgRemoval,
    required this.contrast,
    required this.brightness,
    required this.strokes,
    this.imageBytes,
  });
  factory SignatureState.initial() => const SignatureState(
    rect: null,
    aspectLocked: false,
    bgRemoval: false,
    contrast: 1.0,
    brightness: 0.0,
    strokes: [],
    imageBytes: null,
  );
  SignatureState copyWith({
    Rect? rect,
    bool? aspectLocked,
    bool? bgRemoval,
    double? contrast,
    double? brightness,
    List<List<Offset>>? strokes,
    Uint8List? imageBytes,
  }) => SignatureState(
    rect: rect ?? this.rect,
    aspectLocked: aspectLocked ?? this.aspectLocked,
    bgRemoval: bgRemoval ?? this.bgRemoval,
    contrast: contrast ?? this.contrast,
    brightness: brightness ?? this.brightness,
    strokes: strokes ?? this.strokes,
    imageBytes: imageBytes ?? this.imageBytes,
  );
}
