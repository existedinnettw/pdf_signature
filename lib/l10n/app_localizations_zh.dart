// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'PDF 簽名';

  @override
  String errorWithMessage(String message) {
    return '錯誤：$message';
  }

  @override
  String get settings => '設定';

  @override
  String get theme => '主題';

  @override
  String get themeLight => '淺色';

  @override
  String get themeDark => '深色';

  @override
  String get themeSystem => '系統';

  @override
  String get language => '語言';

  @override
  String get languageEnglish => '英文';

  @override
  String get languageChineseTraditional => '繁體中文';

  @override
  String get languageSpanish => '西班牙文';

  @override
  String get resetToDefaults => '重設為預設值';

  @override
  String get openPdf => '開啟 PDF…';

  @override
  String get prev => '上一頁';

  @override
  String get next => '下一頁';

  @override
  String pageInfo(int current, int total) {
    return '第 $current/$total 頁';
  }

  @override
  String get goTo => '前往：';

  @override
  String get dpi => 'DPI：';

  @override
  String get markForSigning => '標記簽署';

  @override
  String get unmarkSigning => '取消標記';

  @override
  String get saveSignedPdf => '儲存已簽名 PDF';

  @override
  String get loadSignatureFromFile => '從檔案載入簽名';

  @override
  String get drawSignature => '手寫簽名';

  @override
  String get noPdfLoaded => '尚未載入 PDF';

  @override
  String get signature => '簽名';

  @override
  String get lockAspectRatio => '鎖定長寬比';

  @override
  String get backgroundRemoval => '去除背景';

  @override
  String get contrast => '對比';

  @override
  String get brightness => '亮度';

  @override
  String get exportingPleaseWait => '匯出中…請稍候';

  @override
  String get nothingToSaveYet => '尚無可儲存的內容';

  @override
  String savedWithPath(String path) {
    return '已儲存：$path';
  }

  @override
  String get failedToSavePdf => '儲存 PDF 失敗';

  @override
  String get downloadStarted => '已開始下載';

  @override
  String get failedToGeneratePdf => '產生 PDF 失敗';

  @override
  String get invalidOrUnsupportedFile => '無效或不支援的檔案';

  @override
  String get confirm => '確認';

  @override
  String get undo => '復原';

  @override
  String get clear => '清除';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => 'PDF 簽名';

  @override
  String errorWithMessage(String message) {
    return '錯誤：$message';
  }

  @override
  String get settings => '設定';

  @override
  String get theme => '主題';

  @override
  String get themeLight => '淺色';

  @override
  String get themeDark => '深色';

  @override
  String get themeSystem => '系統';

  @override
  String get language => '語言';

  @override
  String get languageEnglish => '英文';

  @override
  String get languageChineseTraditional => '繁體中文';

  @override
  String get languageSpanish => '西班牙文';

  @override
  String get resetToDefaults => '重設為預設值';

  @override
  String get openPdf => '開啟 PDF…';

  @override
  String get prev => '上一頁';

  @override
  String get next => '下一頁';

  @override
  String pageInfo(int current, int total) {
    return '第 $current/$total 頁';
  }

  @override
  String get goTo => '前往：';

  @override
  String get dpi => 'DPI：';

  @override
  String get markForSigning => '標記簽署';

  @override
  String get unmarkSigning => '取消標記';

  @override
  String get saveSignedPdf => '儲存已簽名 PDF';

  @override
  String get loadSignatureFromFile => '從檔案載入簽名';

  @override
  String get drawSignature => '手寫簽名';

  @override
  String get noPdfLoaded => '尚未載入 PDF';

  @override
  String get signature => '簽名';

  @override
  String get lockAspectRatio => '鎖定長寬比';

  @override
  String get backgroundRemoval => '去除背景';

  @override
  String get contrast => '對比';

  @override
  String get brightness => '亮度';

  @override
  String get exportingPleaseWait => '匯出中…請稍候';

  @override
  String get nothingToSaveYet => '尚無可儲存的內容';

  @override
  String savedWithPath(String path) {
    return '已儲存：$path';
  }

  @override
  String get failedToSavePdf => '儲存 PDF 失敗';

  @override
  String get downloadStarted => '已開始下載';

  @override
  String get failedToGeneratePdf => '產生 PDF 失敗';

  @override
  String get invalidOrUnsupportedFile => '無效或不支援的檔案';

  @override
  String get confirm => '確認';

  @override
  String get undo => '復原';

  @override
  String get clear => '清除';
}
