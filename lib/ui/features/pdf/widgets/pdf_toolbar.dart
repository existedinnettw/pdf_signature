import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';

class PdfToolbar extends ConsumerStatefulWidget {
  const PdfToolbar({
    super.key,
    required this.disabled,
    required this.onPickPdf,
    required this.onClosePdf,
    required this.onJumpToPage,
    required this.onZoomOut,
    required this.onZoomIn,
    this.zoomLevel,
    this.filePath,
    required this.showPagesSidebar,
    required this.showSignaturesSidebar,
    required this.onTogglePagesSidebar,
    required this.onToggleSignaturesSidebar,
  });

  final bool disabled;
  final VoidCallback onPickPdf;
  final VoidCallback onClosePdf;
  final ValueChanged<int> onJumpToPage;
  final String? filePath;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;
  // Current zoom level as a percentage (e.g., 100 for 100%)
  final int? zoomLevel;
  final bool showPagesSidebar;
  final bool showSignaturesSidebar;
  final VoidCallback onTogglePagesSidebar;
  final VoidCallback onToggleSignaturesSidebar;

  @override
  ConsumerState<PdfToolbar> createState() => _PdfToolbarState();
}

class _PdfToolbarState extends ConsumerState<PdfToolbar> {
  final TextEditingController _goToController = TextEditingController();

  @override
  void dispose() {
    _goToController.dispose();
    super.dispose();
  }

  void _submitGoTo() {
    final v = _goToController.text.trim();
    final n = int.tryParse(v);
    if (n != null) widget.onJumpToPage(n);
  }

  @override
  Widget build(BuildContext context) {
    final pdfViewModel = ref.watch(pdfViewModelProvider);
    final pdf = ref.watch(
      documentRepositoryProvider,
    ); // Watch document directly for updates
    final currentPage = pdfViewModel.currentPage;
    final l = AppLocalizations.of(context);
    final pageInfo = l.pageInfo(currentPage, pdf.pageCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 260;
        final double gotoWidth = 50;
        // Be defensive in tests that don't provide ResponsiveBreakpoints
        final bool isLargerThanMobile = () {
          try {
            return ResponsiveBreakpoints.of(context).largerThan(MOBILE);
          } catch (_) {
            return true; // default to full toolbar on tests/minimal hosts
          }
        }();
        final String fileDisplay = () {
          final path = widget.filePath;
          if (path == null || path.isEmpty) return 'No file selected';
          if (isLargerThanMobile) return path;
          // Extract file name for mobile (supports both / and \ separators)
          return path.split('/').last.split('\\').last;
        }();

        // Center content of the toolbar
        final center = Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton(
              key: const Key('btn_open_pdf_picker'),
              onPressed: widget.disabled ? null : widget.onPickPdf,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.insert_drive_file, size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(
                        fileDisplay,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (pdf.loaded) ...[
              IconButton(
                key: const Key('btn_close_pdf'),
                onPressed: widget.disabled ? null : widget.onClosePdf,
                icon: const Icon(Icons.close),
                tooltip: l.close,
              ),
              Wrap(
                spacing: 8,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      IconButton(
                        key: const Key('btn_prev'),
                        onPressed:
                            widget.disabled
                                ? null
                                : () => widget.onJumpToPage(-1),
                        icon: const Icon(Icons.chevron_left),
                        tooltip: l.prev,
                      ),
                      // Current page label
                      Text(pageInfo, key: const Key('lbl_page_info')),
                      IconButton(
                        key: const Key('btn_next'),
                        onPressed:
                            widget.disabled
                                ? null
                                : () => widget.onJumpToPage(currentPage + 1),
                        icon: const Icon(Icons.chevron_right),
                        tooltip: l.next,
                      ),
                    ],
                  ),
                  if (isLargerThanMobile)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(l.goTo),
                        SizedBox(
                          width: gotoWidth,
                          child: TextField(
                            key: const Key('txt_goto'),
                            controller: _goToController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            enabled: !widget.disabled,
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: '1..${pdf.pageCount}',
                            ),
                            onSubmitted: (_) => _submitGoTo(),
                          ),
                        ),
                        if (!compact)
                          IconButton(
                            key: const Key('btn_goto_apply'),
                            tooltip: l.goTo,
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: widget.disabled ? null : _submitGoTo,
                          ),
                      ],
                    ),

                  if (isLargerThanMobile) ...[
                    const SizedBox(width: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        IconButton(
                          key: const Key('btn_zoom_out'),
                          tooltip: 'Zoom out',
                          onPressed: widget.disabled ? null : widget.onZoomOut,
                          icon: const Icon(Icons.zoom_out),
                        ),
                        Text(
                          //if not null
                          widget.zoomLevel != null
                              ? '${widget.zoomLevel}%'
                              : '',
                          style: const TextStyle(fontSize: 12),
                        ),
                        IconButton(
                          key: const Key('btn_zoom_in'),
                          tooltip: 'Zoom in',
                          onPressed: widget.disabled ? null : widget.onZoomIn,
                          icon: const Icon(Icons.zoom_in),
                        ),
                      ],
                    ),
                    SizedBox(width: 6),
                  ],
                ],
              ),
            ],
          ],
        );

        return Row(
          children: [
            if (isLargerThanMobile) ...[
              IconButton(
                key: const Key('btn_toggle_pages_sidebar'),
                tooltip: 'Toggle pages overview',
                onPressed: widget.disabled ? null : widget.onTogglePagesSidebar,
                icon: Icon(
                  Icons.view_sidebar,
                  color:
                      widget.showPagesSidebar
                          ? Theme.of(context).colorScheme.primary
                          : null,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(child: center),
            const SizedBox(width: 8),
            IconButton(
              key: const Key('btn_toggle_signatures_sidebar'),
              tooltip: 'Toggle signatures drawer',
              onPressed:
                  widget.disabled ? null : widget.onToggleSignaturesSidebar,
              icon: Icon(
                Icons.view_sidebar,
                color:
                    widget.showSignaturesSidebar
                        ? Theme.of(context).colorScheme.primary
                        : null,
              ),
            ),
          ],
        );
      },
    );
  }
}
