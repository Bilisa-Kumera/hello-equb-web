import 'dart:html' as html;
import 'dart:typed_data';

class FileHandleApi {
  static Future<void> openPdfBytes({
    required Uint8List bytes,
    required String name,
  }) async {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = name
      ..target = '_blank';
    anchor.click();
    html.Url.revokeObjectUrl(url);
  }
}

