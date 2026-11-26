import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<String?> downloadPdfBytes(Uint8List bytes, String filename) async {
  Directory? directory;
  try {
    directory = await getDownloadsDirectory();
  } catch (_) {
    directory = null;
  }
  directory ??= await getApplicationDocumentsDirectory();
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
  final file = File('${directory.path}${Platform.pathSeparator}$filename');
  await file.writeAsBytes(bytes, flush: true);

  if (Platform.isAndroid || Platform.isIOS) {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Bivio Quiz result',
        text: 'Bivio Quiz result PDF',
      ),
    );
  }

  return file.path;
}
