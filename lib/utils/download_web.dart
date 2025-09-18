// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

Future<bool> downloadBytes(Uint8List bytes, {required String filename}) async {
  try {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor =
        html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..download = filename
          ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
    return true;
  } catch (_) {
    return false;
  }
}
