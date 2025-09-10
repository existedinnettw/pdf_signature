import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';

import 'package:pdf_signature/data/repositories/pdf_repository.dart';

class PdfToolbar extends ConsumerStatefulWidget {
  const PdfToolbar({
    super.key,
    required this.disabled,
    required this.onPickPdf,
    required this.onJumpToPage,
    required this.onZoomOut,
    required this.onZoomIn,
    this.zoomLevel,
    this.fileName,
    required this.showPagesSidebar,
    required this.showSignaturesSidebar,
    required this.onTogglePagesSidebar,
    required this.onToggleSignaturesSidebar,
  });

  final bool disabled;
  final VoidCallback onPickPdf;
  final ValueChanged<int> onJumpToPage;
  final String? fileName;
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
    final pdf = ref.watch(documentRepositoryProvider);
    final l = AppLocalizations.of(context);
    final pageInfo = l.pageInfo(pdf.currentPage, pdf.pageCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 260;
        final double gotoWidth = 50;

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
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      // if filename not null
                      widget.fileName != null
                          ? widget.fileName!
                          : 'No file selected',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (pdf.loaded) ...[
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
                                : () =>
                                    widget.onJumpToPage(pdf.currentPage - 1),
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
                                : () =>
                                    widget.onJumpToPage(pdf.currentPage + 1),
                        icon: const Icon(Icons.chevron_right),
                        tooltip: l.next,
                      ),
                    ],
                  ),
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
                        widget.zoomLevel != null ? '${widget.zoomLevel}%' : '',
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
              ),
            ],
          ],
        );

        return Row(
          children: [
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
