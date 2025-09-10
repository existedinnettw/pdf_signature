import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_signature/l10n/app_localizations.dart';
import 'package:pdf_signature/ui/features/welcome/widgets/welcome_screen.dart';
import 'package:pdf_signature/data/repositories/signature_card_repository.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';

class _FakeDropReadable implements DropReadable {
  final String _name;
  final String? _path;
  final Uint8List _bytes;
  _FakeDropReadable(this._name, this._path, this._bytes);
  @override
  String get name => _name;
  @override
  String? get path => _path;
  @override
  Future<Uint8List> readAsBytes() async => _bytes;
}

void main() {
  testWidgets('dropping a PDF opens it and resets signature state', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WelcomeScreen(),
        ),
      ),
    );

    final stateful = tester.state(find.byType(WelcomeScreen)) as ConsumerState;
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final fake = _FakeDropReadable('sample.pdf', '/tmp/sample.pdf', bytes);

    // Use the top-level helper with the WidgetRef.read function
    await handleDroppedFiles(stateful.ref.read, [fake]);
    await tester.pump();

    final container = ProviderScope.containerOf(stateful.context);
    final pdf = container.read(documentRepositoryProvider);
    expect(pdf.loaded, isTrue);
    expect(pdf.pickedPdfPath, '/tmp/sample.pdf');
    expect(pdf.pickedPdfBytes, bytes);

    final sig = container.read(signatureProvider);
    expect(sig.rect, isNull);
    expect(sig.editingEnabled, isFalse);
  });
}
