import 'package:flutter/widgets.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';

/// Centralized accessors for context menu labels to avoid duplication.
class MenuLabels {
  static String confirm(BuildContext context) =>
      AppLocalizations.of(context).confirm;

  static String delete(BuildContext context) =>
      AppLocalizations.of(context).delete;

  // Not yet localized in l10n; keep here for single source of truth.
  static String adjustGraphic(BuildContext context) => 'Adjust graphic';
}
