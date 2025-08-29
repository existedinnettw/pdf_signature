import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('openPicked loads document and initializes state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(pdfProvider.notifier);
    notifier.openPicked(path: 'test.pdf', pageCount: 7);
    final state = container.read(pdfProvider);
    expect(state.loaded, isTrue);
    expect(state.pickedPdfPath, 'test.pdf');
    expect(state.pageCount, 7);
    expect(state.currentPage, 1);
    expect(state.markedForSigning, isFalse);
  });

  test('jumpTo clamps within page boundaries', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(pdfProvider.notifier);
    notifier.openPicked(path: 'test.pdf', pageCount: 5);
    notifier.jumpTo(10);
    expect(container.read(pdfProvider).currentPage, 5);
    notifier.jumpTo(0);
    expect(container.read(pdfProvider).currentPage, 1);
    notifier.jumpTo(3);
    expect(container.read(pdfProvider).currentPage, 3);
  });

  test('setPageCount updates count without toggling other flags', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(pdfProvider.notifier);
    notifier.openPicked(path: 'test.pdf', pageCount: 2);
    notifier.toggleMark();
    notifier.setPageCount(9);
    final s = container.read(pdfProvider);
    expect(s.pageCount, 9);
    expect(s.loaded, isTrue);
    expect(s.markedForSigning, isTrue);
  });
}
