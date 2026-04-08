import 'dart:io';
import 'package:file_picker/file_picker.dart';

Future<String?> savePdfBytesImpl({
  required List<int> bytes,
  required String fileName,
}) async {
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Save PDF',
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: const ['pdf'],
  );
  if (path == null || path.isEmpty) return null;
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
  return path;
}
