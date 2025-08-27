import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/features/pdf/viewer.dart';

void main() {
  test('placeDefaultRect centers a reasonable default rect', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sig = container.read(signatureProvider);
    // Should be null initially
    expect(sig.rect, isNull);

    // Place using default pageSize (400x560)
    container.read(signatureProvider.notifier).placeDefaultRect();
    final placed = container.read(signatureProvider).rect!;

    // Default should be within bounds and not tiny
    expect(placed.left, greaterThanOrEqualTo(0));
    expect(placed.top, greaterThanOrEqualTo(0));
    expect(placed.right, lessThanOrEqualTo(400));
    expect(placed.bottom, lessThanOrEqualTo(560));
    expect(placed.width, greaterThan(50));
    expect(placed.height, greaterThan(20));
  });

  test('drag clamps to canvas bounds', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(signatureProvider.notifier).placeDefaultRect();
    final before = container.read(signatureProvider).rect!;
    // Drag far outside bounds
    container
        .read(signatureProvider.notifier)
        .drag(const Offset(10000, -10000));
    final after = container.read(signatureProvider).rect!;
    expect(after.left, greaterThanOrEqualTo(0));
    expect(after.top, greaterThanOrEqualTo(0));
    expect(after.right, lessThanOrEqualTo(400));
    expect(after.bottom, lessThanOrEqualTo(560));
    // Ensure it actually moved
    expect(after.center, isNot(equals(before.center)));
  });

  test('resize respects aspect lock and clamps', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(signatureProvider.notifier);
    notifier.placeDefaultRect();
    final before = container.read(signatureProvider).rect!;
    notifier.toggleAspect(true);
    notifier.resize(const Offset(1000, 1000));
    final after = container.read(signatureProvider).rect!;
    // With aspect lock the ratio should remain approximately the same
    final ratioBefore = before.width / before.height;
    final ratioAfter = after.width / after.height;
    expect((ratioBefore - ratioAfter).abs(), lessThan(0.05));
    // Still within bounds
    expect(after.left, greaterThanOrEqualTo(0));
    expect(after.top, greaterThanOrEqualTo(0));
    expect(after.right, lessThanOrEqualTo(400));
    expect(after.bottom, lessThanOrEqualTo(560));
  });

  test('setImageBytes ensures a rect exists for display', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(signatureProvider.notifier);
    expect(container.read(signatureProvider).rect, isNull);
    notifier.setImageBytes(Uint8List.fromList([0, 1, 2]));
    expect(container.read(signatureProvider).imageBytes, isNotNull);
    // placeDefaultRect is called when bytes are set if rect was null
    expect(container.read(signatureProvider).rect, isNotNull);
  });
}
