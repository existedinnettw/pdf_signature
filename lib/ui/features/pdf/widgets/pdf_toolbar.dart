import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';

import '../../../../data/services/providers.dart';
import '../view_model/view_model.dart';

class PdfToolbar extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final pdf = ref.watch(pdfProvider);
    final dpi = ref.watch(exportDpiProvider);
    final l = AppLocalizations.of(context);
    final pageInfo = l.pageInfo(pdf.currentPage, pdf.pageCount);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton(
          key: const Key('btn_open_settings'),
          onPressed: disabled ? null : onOpenSettings,
          child: Text(l.settings),
        ),
        OutlinedButton(
          key: const Key('btn_open_pdf_picker'),
          onPressed: disabled ? null : onPickPdf,
          child: Text(l.openPdf),
        ),
        if (pdf.loaded) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: const Key('btn_prev'),
                onPressed:
                    disabled ? null : () => onJumpToPage(pdf.currentPage - 1),
                icon: const Icon(Icons.chevron_left),
                tooltip: l.prev,
              ),
              Text(pageInfo, key: const Key('lbl_page_info')),
              IconButton(
                key: const Key('btn_next'),
                onPressed:
                    disabled ? null : () => onJumpToPage(pdf.currentPage + 1),
                icon: const Icon(Icons.chevron_right),
                tooltip: l.next,
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.goTo),
              SizedBox(
                width: 60,
                child: TextField(
                  key: const Key('txt_goto'),
                  keyboardType: TextInputType.number,
                  enabled: !disabled,
                  onSubmitted: (v) {
                    final n = int.tryParse(v);
                    if (n != null) onJumpToPage(n);
                  },
                ),
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
                    disabled
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
            onPressed: disabled ? null : onSave,
            child: Text(l.saveSignedPdf),
          ),
          OutlinedButton(
            key: const Key('btn_load_signature_picker'),
            onPressed: disabled || !pdf.loaded ? null : onLoadSignatureFromFile,
            child: Text(l.loadSignatureFromFile),
          ),
          OutlinedButton(
            key: const Key('btn_create_signature'),
            onPressed: disabled || !pdf.loaded ? null : onCreateSignature,
            child: Text(l.createNewSignature),
          ),
          ElevatedButton(
            key: const Key('btn_draw_signature'),
            onPressed: disabled || !pdf.loaded ? null : onOpenDrawCanvas,
            child: Text(l.drawSignature),
          ),
        ],
      ],
    );
  }
}
