import 'package:printing/printing.dart';

Future<String?> savePdfBytesImpl({
  required List<int> bytes,
  required String fileName,
}) async {
  await Printing.layoutPdf(onLayout: (_) async => bytes);
  return null;
}
