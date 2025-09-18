import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../view_model/pdf_view_model.dart';

class ThumbnailsView extends ConsumerWidget {
  const ThumbnailsView({
    super.key,
    required this.documentRef,
    required this.controller,
    required this.currentPage,
  });

  final PdfDocumentRefData documentRef;
  final PdfViewerController controller;
  final int currentPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Access view model to detect mock viewer mode
    final viewModel = ref.read(pdfViewModelProvider);

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
              final isSelected = currentPage == pageNumber;
              return InkWell(
                onTap: () {
                  // For real viewer: navigate first and wait for onPageChanged
                  // to update provider when the page is actually reached.
                  // For mock/unready: update provider immediately to drive scroll.
                  final isRealViewer = !viewModel.useMockViewer;
                  if (isRealViewer && controller.isReady) {
                    controller.goToPage(
                      pageNumber: pageNumber,
                      anchor: PdfPageAnchor.top,
                    );
                    // Do not set provider here; let onPageChanged handle it
                  } else {
                    // In tests or when controller isn't ready, drive state directly
                    try {
                      ref
                          .read(pdfViewModelProvider.notifier)
                          .jumpToPage(pageNumber);
                    } catch (_) {}
                  }
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

class PagesSidebar extends StatelessWidget {
  const PagesSidebar({
    super.key,
    required this.documentRef,
    required this.controller,
    required this.currentPage,
  });

  final PdfDocumentRefData? documentRef;
  final PdfViewerController controller;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    if (documentRef == null) {
      return Card(margin: EdgeInsets.zero, child: const SizedBox.shrink());
    }

    return Card(
      margin: EdgeInsets.zero,
      child: ThumbnailsView(
        documentRef: documentRef!,
        controller: controller,
        currentPage: currentPage,
      ),
    );
  }
}
