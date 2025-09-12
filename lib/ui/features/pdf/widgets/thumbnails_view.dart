import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import '../view_model/pdf_providers.dart';

class ThumbnailsView extends ConsumerWidget {
  const ThumbnailsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdf = ref.watch(documentRepositoryProvider);
    final controller = ref.watch(pdfViewerControllerProvider);
    final theme = Theme.of(context);

    if (!pdf.loaded || pdf.pickedPdfBytes == null)
      return const SizedBox.shrink();

    final documentRef = PdfDocumentRefData(
      pdf.pickedPdfBytes!,
      sourceName: 'document.pdf',
    );

    return Container(
      color: theme.colorScheme.surface,
      child: PdfDocumentViewBuilder(
        documentRef: documentRef,
        builder: (context, document) {
          final pageCount = document?.pages.length ?? 0;
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            itemCount: pageCount,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final pageNumber = index + 1;
              final isSelected = ref.watch(currentPageProvider) == pageNumber;
              return InkWell(
                onTap: () {
                  controller.goToPage(
                    pageNumber: pageNumber,
                    anchor: PdfPageAnchor.top,
                  );
                },
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
                    child: Column(
                      children: [
                        SizedBox(
                          height: 180,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: PdfPageView(
                              document: document,
                              pageNumber: pageNumber,
                              alignment: Alignment.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('$pageNumber', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
