import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';

import 'signature_drawer.dart';
import 'ui_services.dart';

class SignaturesSidebar extends ConsumerWidget {
  const SignaturesSidebar({
    super.key,
    required this.onLoadSignatureFromFile,
    required this.onOpenDrawCanvas,
    required this.onSave,
  });

  final Future<Uint8List?> Function() onLoadSignatureFromFile;
  final Future<Uint8List?> Function() onOpenDrawCanvas;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final isExporting = ref.watch(exportingProvider);
    return AbsorbPointer(
      absorbing: isExporting,
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: SignatureDrawer(
                  disabled: isExporting,
                  onLoadSignatureFromFile: onLoadSignatureFromFile,
                  onOpenDrawCanvas: onOpenDrawCanvas,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton(
                key: const Key('btn_save_pdf'),
                onPressed: isExporting ? null : onSave,
                child: Text(l.saveSignedPdf),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
