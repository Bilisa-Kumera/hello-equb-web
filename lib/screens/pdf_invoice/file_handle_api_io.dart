import 'dart:io';
import 'dart:typed_data';

import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class FileHandleApi {
  static Future<void> openPdfBytes({
    required Uint8List bytes,
    required String name,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    await OpenFile.open(file.path);
  }
}

