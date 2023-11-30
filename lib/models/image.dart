import 'dart:io';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

class ImageUnit {
  final String key;
  final Uint8List bytes;
  final bool fromFile;

  ImageUnit({required this.bytes, required this.fromFile})
      : key = const Uuid().v4().toString();

  factory ImageUnit.file({required File file}) {
    return ImageUnit(bytes: file.readAsBytesSync(), fromFile: true);
  }

  factory ImageUnit.bytes({required Uint8List bytes}) {
    return ImageUnit(bytes: bytes, fromFile: false);
  }
}
