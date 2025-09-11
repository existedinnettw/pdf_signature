import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'pdf_providers.dart';
import '../view_model/pdf_view_model.dart';

class PdfPagesOverview extends ConsumerWidget {
  const PdfPagesOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdf = ref.watch(documentRepositoryProvider);
    ref.watch(useMockViewerProvider);
    final theme = Theme.of(context);

    if (!pdf.loaded) return const SizedBox.shrink();

    Widget buildList(int pageCount, {Widget Function(int i)? item}) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        itemCount: pageCount,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final pageNumber = index + 1;
          final isSelected = ref.watch(pdfViewModelProvider) == pageNumber;
          return InkWell(
            onTap:
                () => ref
                    .read(pdfViewModelProvider.notifier)
                    .jumpToPage(pageNumber),
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

    final count = pdf.pageCount == 0 ? 1 : pdf.pageCount;
    return buildList(count);
  }
}
