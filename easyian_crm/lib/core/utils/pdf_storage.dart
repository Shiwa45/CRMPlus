import 'pdf_storage_stub.dart'
    if (dart.library.html) 'pdf_storage_web.dart'
    if (dart.library.io) 'pdf_storage_io.dart';

/// Save or present a PDF depending on platform.
/// Returns a saved file path on IO platforms, or null on web.
Future<String?> savePdfBytes({
  required List<int> bytes,
  required String fileName,
}) =>
    savePdfBytesImpl(bytes: bytes, fileName: fileName);
