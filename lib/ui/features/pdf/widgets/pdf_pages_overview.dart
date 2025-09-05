import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../data/services/export_providers.dart';
import '../view_model/pdf_controller.dart';

class PdfPagesOverview extends ConsumerWidget {
  const PdfPagesOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdf = ref.watch(pdfProvider);
    final useMock = ref.watch(useMockViewerProvider);
    final theme = Theme.of(context);

    if (!pdf.loaded) return const SizedBox.shrink();

    Widget buildList(int pageCount, {Widget Function(int i)? item}) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        itemCount: pageCount,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final pageNumber = index + 1;
          final isSelected = pdf.currentPage == pageNumber;
          return InkWell(
            onTap: () => ref.read(pdfProvider.notifier).jumpTo(pageNumber),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? theme.colorScheme.primaryContainer
                        : theme.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      isSelected
                          ? theme.colorScheme.primary
                          : theme.dividerColor,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: AspectRatio(
                  aspectRatio: 1 / 1.4142, // A4 portrait approx
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child:
                        item != null
                            ? item(index)
                            : Center(child: Text('$pageNumber')),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    if (useMock) {
      final count = pdf.pageCount == 0 ? 1 : pdf.pageCount;
      return buildList(count);
    }

    if (pdf.pickedPdfPath != null) {
      return PdfDocumentViewBuilder.file(
        pdf.pickedPdfPath!,
        builder: (context, document) {
          if (document == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final pages = document.pages;
          if (pdf.pageCount != pages.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(pdfProvider.notifier).setPageCount(pages.length);
            });
          }
          return buildList(
            pages.length,
            item:
                (i) => PdfPageView(
                  document: document,
                  pageNumber: i + 1,
                  alignment: Alignment.center,
                ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}
