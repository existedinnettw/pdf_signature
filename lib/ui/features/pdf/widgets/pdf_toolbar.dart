import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';

import '../../../../data/services/providers.dart';
import '../view_model/view_model.dart';

class PdfToolbar extends ConsumerStatefulWidget {
  const PdfToolbar({
    super.key,
    required this.disabled,
    required this.onOpenSettings,
    required this.onPickPdf,
    required this.onJumpToPage,
    required this.onSave,
    required this.onLoadSignatureFromFile,
    required this.onCreateSignature,
    required this.onOpenDrawCanvas,
  });

  final bool disabled;
  final VoidCallback onOpenSettings;
  final VoidCallback onPickPdf;
  final ValueChanged<int> onJumpToPage;
  final VoidCallback onSave;
  final VoidCallback onLoadSignatureFromFile;
  final VoidCallback onCreateSignature;
  final VoidCallback onOpenDrawCanvas;

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
    final pdf = ref.watch(pdfProvider);
    final dpi = ref.watch(exportDpiProvider);
    final l = AppLocalizations.of(context);
    final pageInfo = l.pageInfo(pdf.currentPage, pdf.pageCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 260;
        final double gotoWidth = compact ? 60 : 100;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton(
              key: const Key('btn_open_settings'),
              onPressed: widget.disabled ? null : widget.onOpenSettings,
              child: Text(l.settings),
            ),
            OutlinedButton(
              key: const Key('btn_open_pdf_picker'),
              onPressed: widget.disabled ? null : widget.onPickPdf,
              child: Text(l.openPdf),
            ),
            if (pdf.loaded) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: const Key('btn_prev'),
                    onPressed:
                        widget.disabled
                            ? null
                            : () => widget.onJumpToPage(pdf.currentPage - 1),
                    icon: const Icon(Icons.chevron_left),
                    tooltip: l.prev,
                  ),
                  Text(pageInfo, key: const Key('lbl_page_info')),
                  IconButton(
                    key: const Key('btn_next'),
                    onPressed:
                        widget.disabled
                            ? null
                            : () => widget.onJumpToPage(pdf.currentPage + 1),
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
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l.dpi),
                  const SizedBox(width: 8),
                  DropdownButton<double>(
                    key: const Key('ddl_export_dpi'),
                    value: dpi,
                    items:
                        const [96.0, 144.0, 200.0, 300.0]
                            .map(
                              (v) => DropdownMenuItem(
                                value: v,
                                child: Text(v.toStringAsFixed(0)),
                              ),
                            )
                            .toList(),
                    onChanged:
                        widget.disabled
                            ? null
                            : (v) {
                              if (v != null) {
                                ref.read(exportDpiProvider.notifier).state = v;
                              }
                            },
                  ),
                ],
              ),
              ElevatedButton(
                key: const Key('btn_save_pdf'),
                onPressed: widget.disabled ? null : widget.onSave,
                child: Text(l.saveSignedPdf),
              ),
              OutlinedButton(
                key: const Key('btn_load_signature_picker'),
                onPressed:
                    widget.disabled || !pdf.loaded
                        ? null
                        : widget.onLoadSignatureFromFile,
                child: Text(l.loadSignatureFromFile),
              ),
              OutlinedButton(
                key: const Key('btn_create_signature'),
                onPressed:
                    widget.disabled || !pdf.loaded
                        ? null
                        : widget.onCreateSignature,
                child: Text(l.createNewSignature),
              ),
              ElevatedButton(
                key: const Key('btn_draw_signature'),
                onPressed:
                    widget.disabled || !pdf.loaded
                        ? null
                        : widget.onOpenDrawCanvas,
                child: Text(l.drawSignature),
              ),
            ],
          ],
        );
      },
    );
  }
}
