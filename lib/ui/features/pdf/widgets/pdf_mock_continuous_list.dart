import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';

import '../../../../data/services/export_providers.dart';
import 'pdf_page_overlays.dart';

/// Mocked continuous viewer for tests or platforms without real viewer.
class PdfMockContinuousList extends ConsumerWidget {
  const PdfMockContinuousList({
    super.key,
    required this.pageSize,
    required this.count,
    required this.pageKeyBuilder,
    required this.scrollToPage,
    this.onDragSignature,
    this.onResizeSignature,
    this.onConfirmSignature,
    this.onClearActiveOverlay,
    this.onSelectPlaced,
    this.pendingPage,
    this.clearPending,
  });

  final Size pageSize;
  final int count;
  final GlobalKey Function(int page) pageKeyBuilder;
  final void Function(int page) scrollToPage;
  final int? pendingPage;
  final VoidCallback? clearPending;

  final ValueChanged<Offset>? onDragSignature;
  final ValueChanged<Offset>? onResizeSignature;
  final VoidCallback? onConfirmSignature;
  final VoidCallback? onClearActiveOverlay;
  final ValueChanged<int?>? onSelectPlaced;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pendingPage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final p = pendingPage;
        if (p != null) {
          clearPending?.call();
          scheduleMicrotask(() => scrollToPage(p));
        }
      });
    }

    return SingleChildScrollView(
      key: const Key('pdf_continuous_mock_list'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: List.generate(count, (idx) {
          final pageNum = idx + 1;
          return Center(
            child: Padding(
              key: pageKeyBuilder(pageNum),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: AspectRatio(
                aspectRatio: pageSize.width / pageSize.height,
                child: Stack(
                  key: ValueKey('page_stack_$pageNum'),
                  children: [
                    Container(
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Builder(
                          builder: (ctx) {
                            String label;
                            try {
                              label = AppLocalizations.of(
                                ctx,
                              ).pageInfo(pageNum, count);
                            } catch (_) {
                              label = 'Page $pageNum of $count';
                            }
                            return Text(
                              label,
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.black54,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final visible = ref.watch(signatureVisibilityProvider);
                        return visible
                            ? PdfPageOverlays(
                              pageSize: pageSize,
                              pageNumber: pageNum,
                              onDragSignature: onDragSignature,
                              onResizeSignature: onResizeSignature,
                              onConfirmSignature: onConfirmSignature,
                              onClearActiveOverlay: onClearActiveOverlay,
                              onSelectPlaced: onSelectPlaced,
                            )
                            : const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
