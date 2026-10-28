import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class SelectedBiometricFile {
  const SelectedBiometricFile(
      {required this.name,
      required this.size,
      required this.selectedAt,
      required this.bytes});
  final String name;
  final int size;
  final DateTime selectedAt;
  final Uint8List bytes;
}

class BiometricFilePicker {
  Future<SelectedBiometricFile?> selectFile() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['dat', 'txt'],
        allowMultiple: false,
        withData: true);
    if (result == null) return null;
    final file = result.files.single;
    if (!RegExp(r'\.(dat|txt)$', caseSensitive: false).hasMatch(file.name)) {
      throw const FormatException('Seleccione un archivo .dat o .txt.');
    }
    if (file.bytes == null) {
      throw const FormatException(
          'No se pudo acceder al contenido del archivo.');
    }
    return SelectedBiometricFile(
        name: file.name,
        size: file.size,
        selectedAt: DateTime.now(),
        bytes: file.bytes!);
  }
}
