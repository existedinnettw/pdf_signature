import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';

// Abstraction to make drop handling testable without constructing
// platform-specific DropItem types in widget tests.
abstract class DropReadable {
  String get name;
  String? get path; // may be null on some platforms
  Future<Uint8List> readAsBytes();
}

class _DropReadableFromDesktop implements DropReadable {
  final DropItemFile inner;
  _DropReadableFromDesktop(this.inner);
  @override
  String get name => inner.name;
  @override
  String? get path => inner.path;
  @override
  Future<Uint8List> readAsBytes() => inner.readAsBytes();
}

// Select first .pdf file (case-insensitive) or fall back to first entry.
Future<void> handleDroppedFiles(
  Future<void> Function({String? path, Uint8List? bytes, String? fileName})
  onOpenPdf,
  Iterable<DropReadable> files,
) async {
  if (files.isEmpty) return;
  final pdf = files.firstWhere(
    (f) => (f.name.toLowerCase()).endsWith('.pdf'),
    orElse: () => files.first,
  );
  Uint8List? bytes;
  try {
    bytes = await pdf.readAsBytes();
  } catch (_) {
    bytes = null;
  }
  final String path = pdf.path ?? pdf.name;
  await onOpenPdf(path: path, bytes: bytes, fileName: pdf.name);
}

class WelcomeScreen extends ConsumerStatefulWidget {
  final Future<void> Function() onPickPdf;
  final Future<void> Function({
    String? path,
    Uint8List? bytes,
    String? fileName,
  })
  onOpenPdf;

  const WelcomeScreen({
    super.key,
    required this.onPickPdf,
    required this.onOpenPdf,
  });

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _dragging = false;

  Future<void> _pickPdf() async {
    await widget.onPickPdf();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.picture_as_pdf,
          size: 64,
          color: Theme.of(context).hintColor,
        ),
        const SizedBox(height: 12),
        Text(
          l.noPdfLoaded,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          key: const Key('btn_open_pdf_welcome'),
          onPressed: _pickPdf,
          icon: const Icon(Icons.folder_open),
          label: Text(l.openPdf),
        ),
      ],
    );

    // Use desktop_drop on desktop and mobile; web drag&drop not handled here
    final dropZone = DropTarget(
      enable: !kIsWeb,
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (details) async {
        final desktopFiles = details.files.whereType<DropItemFile>();
        final adapters = desktopFiles.map<DropReadable>(
          (f) => _DropReadableFromDesktop(f),
        );
        await handleDroppedFiles(widget.onOpenPdf, adapters);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                _dragging
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
            width: 2,
          ),
          color:
              _dragging
                  ? Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.05)
                  : Colors.transparent,
        ),
        child: content,
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: dropZone,
      ),
    );
  }
}
