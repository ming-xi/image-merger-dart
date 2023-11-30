import 'dart:io';
import 'dart:typed_data';

import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart';

(int, int) getImageSizeFromBytes(Uint8List bytes) =>
    _applyRotation(ImageSizeGetter.getSize(MemoryInput(bytes)));

(int, int) getImageSizeFromFile(File file) =>
    _applyRotation(ImageSizeGetter.getSize(FileInput(file)));

(int, int) _applyRotation(Size size) {
  var width = size.width;
  var height = size.height;
  if (size.needRotate) {
    width = size.height;
    height = size.width;
  }
  return (width, height);
}
