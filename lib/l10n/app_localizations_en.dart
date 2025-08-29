// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PDF Signature';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChineseTraditional => 'Traditional Chinese';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get resetToDefaults => 'Reset to defaults';

  @override
  String get openPdf => 'Open PDF...';

  @override
  String get prev => 'Prev';

  @override
  String get next => 'Next';

  @override
  String pageInfo(int current, int total) {
    return 'Page $current/$total';
  }

  @override
  String get goTo => 'Go to:';

  @override
  String get dpi => 'DPI:';

  @override
  String get markForSigning => 'Mark for Signing';

  @override
  String get unmarkSigning => 'Unmark Signing';

  @override
  String get saveSignedPdf => 'Save Signed PDF';

  @override
  String get loadSignatureFromFile => 'Load Signature from file';

  @override
  String get drawSignature => 'Draw Signature';

  @override
  String get noPdfLoaded => 'No PDF loaded';

  @override
  String get signature => 'Signature';

  @override
  String get lockAspectRatio => 'Lock aspect ratio';

  @override
  String get backgroundRemoval => 'Background removal';

  @override
  String get contrast => 'Contrast';

  @override
  String get brightness => 'Brightness';

  @override
  String get exportingPleaseWait => 'Exporting... Please wait';

  @override
  String get nothingToSaveYet => 'Nothing to save yet';

  @override
  String savedWithPath(String path) {
    return 'Saved: $path';
  }

  @override
  String get failedToSavePdf => 'Failed to save PDF';

  @override
  String get downloadStarted => 'Download started';

  @override
  String get failedToGeneratePdf => 'Failed to generate PDF';

  @override
  String get invalidOrUnsupportedFile => 'Invalid or unsupported file';

  @override
  String get confirm => 'Confirm';

  @override
  String get undo => 'Undo';

  @override
  String get clear => 'Clear';
}
