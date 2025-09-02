import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: the user assigns {"bob.png"} to the selected signature
Future<void> theUserAssignsToTheSelectedSignature(
  WidgetTester tester,
  String newImageName,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  // Load the new image into signature state (simulating pick)
  Uint8List bytes =
      newImageName == 'bob.png'
          ? Uint8List.fromList([4, 5, 6])
          : Uint8List.fromList([1, 2, 3]);
  container.read(signatureProvider.notifier).setImageBytes(bytes);
  TestWorld.currentImageName = newImageName;
  // Assign to currently selected placement
  final pdf = container.read(pdfProvider);
  final page = pdf.currentPage;
  final idx =
      pdf.selectedPlacementIndex ??
      ((pdf.placementsByPage[page]?.length ?? 1) - 1);
  container
      .read(pdfProvider.notifier)
      .assignImageToPlacement(page: page, index: idx, image: newImageName);
}
