library file_picker;

export './src/file_picker.dart';
export './src/platform_file.dart';
export './src/file_picker_result.dart';
export './src/linux/file_picker_linux.dart'
    if (dart.library.html) './src/_internal/empty.dart';
export './src/file_picker_macos.dart'
    if (dart.library.html) './src/_internal/empty.dart';
export './src/windows/file_picker_windows.dart'
    if (dart.library.html) './src/_internal/empty.dart';
