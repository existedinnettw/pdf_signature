// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Firma PDF';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get settings => 'Ajustes';

  @override
  String get theme => 'Tema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeSystem => 'Del sistema';

  @override
  String get language => 'Idioma';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageChineseTraditional => 'Chino tradicional';

  @override
  String get languageSpanish => 'Español';

  @override
  String get resetToDefaults => 'Restablecer valores';

  @override
  String get openPdf => 'Abrir PDF…';

  @override
  String get prev => 'Anterior';

  @override
  String get next => 'Siguiente';

  @override
  String pageInfo(int current, int total) {
    return 'Página $current/$total';
  }

  @override
  String get goTo => 'Ir a:';

  @override
  String get dpi => 'DPI:';

  @override
  String get markForSigning => 'Marcar para firmar';

  @override
  String get unmarkSigning => 'Quitar marca';

  @override
  String get saveSignedPdf => 'Guardar PDF firmado';

  @override
  String get loadSignatureFromFile => 'Cargar firma desde archivo';

  @override
  String get drawSignature => 'Dibujar firma';

  @override
  String get noPdfLoaded => 'No hay PDF cargado';

  @override
  String get signature => 'Firma';

  @override
  String get lockAspectRatio => 'Bloquear relación de aspecto';

  @override
  String get backgroundRemoval => 'Eliminación de fondo';

  @override
  String get contrast => 'Contraste';

  @override
  String get brightness => 'Brillo';

  @override
  String get exportingPleaseWait => 'Exportando... Por favor espera';

  @override
  String get nothingToSaveYet => 'Nada que guardar todavía';

  @override
  String savedWithPath(String path) {
    return 'Guardado: $path';
  }

  @override
  String get failedToSavePdf => 'Error al guardar el PDF';

  @override
  String get downloadStarted => 'Descarga iniciada';

  @override
  String get failedToGeneratePdf => 'Error al generar el PDF';

  @override
  String get invalidOrUnsupportedFile => 'Archivo no válido o no compatible';

  @override
  String get confirm => 'Confirmar';

  @override
  String get undo => 'Deshacer';

  @override
  String get clear => 'Limpiar';
}
