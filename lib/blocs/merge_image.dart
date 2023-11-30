import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_merger_dart/models/image.dart';
import 'package:image_merger_dart/ui/widgets/images.dart';
import 'package:image_merger_dart/utils/constants.dart';
import 'package:image_merger_dart/utils/image.dart';
import 'package:image_merger_dart/utils/logger.dart';
import 'package:image_merger_dart/utils/string.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

import 'base.dart';

class MergeImageBloc extends BaseBloc {
  static const double defaultOffsetStart = 0.65;
  static const double defaultOffsetEnd = 0.85;

  final BehaviorSubject<List<ImageUnit>> _files = BehaviorSubject.seeded([]);
  final BehaviorSubject<bool> _movieMode = BehaviorSubject.seeded(false);
  final BehaviorSubject<List<double>> _overlayOffsetStart =
      BehaviorSubject.seeded([]);
  final BehaviorSubject<List<double>> _overlayOffsetEnd =
      BehaviorSubject.seeded([]);
  final BehaviorSubject<double> _outputQuality = BehaviorSubject.seeded(0.8);
  final BehaviorSubject<double> _outputScale = BehaviorSubject.seeded(0.5);

  ValueStream<List<ImageUnit>> get files => _files.stream;

  ValueStream<bool> get movieMode => _movieMode.stream;

  ValueStream<double> get outputQuality => _outputQuality.stream;

  ValueStream<double> get outputScale => _outputScale.stream;

  ValueStream<List<double>> get overlayOffsetStart =>
      _overlayOffsetStart.stream;

  ValueStream<List<double>> get overlayOffsetEnd => _overlayOffsetEnd.stream;

  ValueStream<double> get uniqueOverlayOffsetStart => _overlayOffsetStart.stream
      .map(
        (e) => e.isEmpty ? MergeImageBloc.defaultOffsetStart : e[0],
      )
      .distinct()
      .shareValue();

  ValueStream<double> get uniqueOverlayOffsetEnd => _overlayOffsetEnd.stream
      .map(
        (e) => e.isEmpty ? MergeImageBloc.defaultOffsetEnd : e[0],
      )
      .distinct()
      .shareValue();

  Stream<bool> get useUniqueOffset => Rx.combineLatest2(
        overlayOffsetStart,
        overlayOffsetEnd,
        (a, b) => a.toSet().length == 1 && b.toSet().length == 1,
      );

  MergeImageBloc();

  @override
  void dispose() {
    _files.close();
    _movieMode.close();
    _overlayOffsetStart.close();
    _overlayOffsetEnd.close();
    _outputQuality.close();
    _outputScale.close();
    super.dispose();
  }

  void setMovieMode(bool value) {
    _movieMode.add(value);
  }

  void setUseUniqueOverlayOffset(bool value) {
    if (value) {
      _overlayOffsetStart
          .add(_files.value.map((e) => _overlayOffsetStart.value[0]).toList());
    } else {}
  }

  void setUniqueOverlayOffsetStart(double value) {
    _overlayOffsetStart.add(_files.value.map((e) => value).toList());
  }

  void setUniqueOverlayOffsetEnd(double value) {
    _overlayOffsetEnd.add(_files.value.map((e) => value).toList());
  }

  void setSpecificOverlayOffsetStart(int index, double value) {
    _overlayOffsetStart.add([..._overlayOffsetStart.value..[index] = value]);
  }

  void setSpecificOverlayOffsetEnd(int index, double value) {
    _overlayOffsetEnd.add([..._overlayOffsetEnd.value..[index] = value]);
  }

  void setOutputQuality(double value) {
    _outputQuality.add(value);
  }

  void setOutputScale(double value) {
    _outputScale.add(value);
  }

  void removeFile(String key) {
    List<ImageUnit> oldFiles = files.value;
    oldFiles.removeWhere((e) => e.key == key);
    _files.add([...oldFiles]);
  }

  Future<void> addFiles(List<ImageUnit> newFiles, {int? index}) async {
    List<ImageUnit> oldFiles = files.value;
    bool useUniqueOffset = _overlayOffsetStart.value.toSet().length == 1 &&
        _overlayOffsetEnd.value.toSet().length == 1;
    if (index != null) {
      if (index < 0 || index > oldFiles.length) {
        logger.e("index越界：index = $index len = ${oldFiles.length}");
        return;
      }
      _files.add([...oldFiles..insertAll(index, newFiles)]);
    } else {
      _files.add([...oldFiles, ...newFiles]);
    }
    _addOffset(
      _overlayOffsetStart,
      index,
      newFiles.length,
      useUniqueOffset,
      defaultOffsetStart,
    );
    _addOffset(
      _overlayOffsetEnd,
      index,
      newFiles.length,
      useUniqueOffset,
      defaultOffsetEnd,
    );
  }

  void _addOffset(
    BehaviorSubject<List<double>> stream,
    int? index,
    int count,
    bool useUniqueOffset,
    double defaultValue,
  ) {
    if (index == null) {
      stream.add([
        ...stream.value,
        ...List.generate(
          count,
          (index) => useUniqueOffset && stream.value.isNotEmpty
              ? stream.value[0]
              : defaultValue,
        ),
      ]);
    } else {
      stream.add([
        ...stream.value
          ..insertAll(
            index,
            List.generate(
              count,
              (index) => useUniqueOffset && stream.value.isNotEmpty
                  ? stream.value[0]
                  : defaultValue,
            ),
          ),
      ]);
    }
  }

  Future<File?> saveImage(
    BuildContext context, {
    bool multiThread = true,
  }) async {
    setLoading(true);
    try {
      var file = await _Task(
        files: _files.value,
        quality: clampDouble(_outputQuality.value, 0.1, 1),
        scaleRatio: clampDouble(outputScale.value, 0.1, 1),
        offsetStarts: _movieMode.value ? _overlayOffsetStart.value : null,
        offsetEnds: _movieMode.value ? _overlayOffsetEnd.value : null,
      )._execute();
      if (file == null) {
        return null;
      }
      if (!isDesktop) {
        if (await saveImageToGallery(file)) {
          return file;
        } else {
          return null;
        }
      } else {
        return file;
      }
    } catch (e, s) {
      setError(e, stack: s);
      return null;
    } finally {
      setLoading(false);
    }
  }
}

class _Task {
  final List<ImageUnit> files;
  final double quality;
  final double scaleRatio;
  final List<double>? offsetStarts;
  final List<double>? offsetEnds;

  _Task({
    required this.files,
    required this.quality,
    required this.scaleRatio,
    List<double>? offsetStarts,
    List<double>? offsetEnds,
  })  : offsetStarts = offsetStarts ?? files.map((e) => 0.0).toList(),
        offsetEnds = offsetEnds ?? files.map((e) => 1.0).toList();

  Future<File?> _execute() async => await compute(_compositeImage2, [
        files,
        quality,
        scaleRatio,
        offsetStarts,
        offsetEnds,
        (await getTemporaryDirectory()).path,
      ]);

  // static Future<File?> _compositeImage(List<dynamic> args) async {
  //   List<ImageUnit> files = args[0];
  //   int width = 0;
  //   // double ratio;
  //   Map<int, (int, int)> sizes = {};
  //   for (int i = 0; i < files.length; i++) {
  //     var imageSize = _getImageSize(files[i]);
  //     width = max(width, imageSize.$1);
  //     sizes[i] = imageSize;
  //     // if (i == 0) {
  //     //   ratio = imageSize.$1 / imageSize.$2;
  //     // }
  //   }
  //
  //   int height = 0;
  //   for (int i = 0; i < files.length; i++) {
  //     var imageSize = sizes[i]!;
  //     height += imageSize.$2 * width ~/ imageSize.$1;
  //   }
  //   img.Image mergedImage = img.Image(width: width, height: height);
  //   height = 0;
  //   for (int i = 0; i < files.length; i++) {
  //     var imageSize = sizes[i]!;
  //     mxLog("decoded image #${i + 1} start", clear: true);
  //     img.Image image = (img.decodeImage(files[i].bytes))!;
  //     mxLog("decoded image #${i + 1} end");
  //     var newHeight = imageSize.$2 * width ~/ imageSize.$1;
  //     mxLog("draw image #${i + 1} start");
  //     img.compositeImage(
  //       mergedImage,
  //       image,
  //       dstX: 0,
  //       dstY: height,
  //       dstW: width,
  //       dstH: newHeight,
  //     );
  //     mxLog("draw image #${i + 1} end");
  //     height += newHeight;
  //   }
  //   mxLog("encode start");
  //   Uint8List bytes = img.encodeJpg(mergedImage);
  //   mxLog("encode end");
  //   File file = File("${args[1]}/temp.jpg");
  //   mxLog("write file start");
  //   file.writeAsBytesSync(bytes);
  //   mxLog("write file end");
  //   return file;
  // }

  static Future<File?> _compositeImage2(List<dynamic> args) async {
    List<ImageUnit> files = args[0];
    double quality = args[1];
    double scaleRatio = args[2];
    List<double> offsetStarts = args[3];
    List<double> offsetEnds = args[4];
    String dir = args[5];
    int maxWidth = 0;
    Map<int, (int, int)> sizes = {};
    int totalHeight = 0;
    for (int i = 0; i < files.length; i++) {
      var imageSize = getImageSizeFromBytes(files[i].bytes);
      maxWidth = max(maxWidth, imageSize.$1);
      sizes[i] = imageSize;
      if (i == 0) {
        totalHeight += imageSize.$2;
      } else {
        var start = offsetStarts[i];
        var end = offsetEnds[i];
        totalHeight +=
            (imageSize.$2 * maxWidth / imageSize.$1 * (end - start)).toInt();
      }
    }
    int outputWidth = (maxWidth * scaleRatio).toInt();
    totalHeight = (totalHeight * scaleRatio).toInt();
    img.Image mergedImage = img.Image(width: outputWidth, height: totalHeight);
    int currentHeight = 0;
    for (int i = 0; i < files.length; i++) {
      var imageSize = sizes[i]!;
      mxLog(
        "decoded image #${i + 1} start ${imageSize.$1}x${imageSize.$2}",
        clear: true,
      );
      img.Image image = (img.decodeImage(files[i].bytes))!;
      mxLog("decoded image #${i + 1} end");
      var start = offsetStarts[i];
      var end = offsetEnds[i];
      mxLog("draw image #${i + 1} start overlay:[$start,$end]");
      if (i > 0 && (start != 0 || end != 1)) {
        mxLog("scale image #${i + 1} start");
        image = img.copyCrop(
          image,
          x: 0,
          y: (imageSize.$2 * start).toInt(),
          width: imageSize.$1,
          height: (imageSize.$2 * (end - start)).toInt(),
        );
        mxLog("scale image #${i + 1} end ${image.width}x${image.height}");
      }
      var scaledHeight = image.height * outputWidth ~/ image.width;
      img.compositeImage(
        mergedImage,
        image,
        dstX: 0,
        dstY: currentHeight,
        dstW: outputWidth,
        dstH: scaledHeight,
      );

      mxLog("draw image #${i + 1} end");
      currentHeight += scaledHeight;
    }
    mxLog("encode start");
    Uint8List bytes =
        img.encodeJpg(mergedImage, quality: (100 * quality).toInt());
    mxLog("encode end");

    File file = File("$dir/temp.jpg");
    mxLog("write file start");
    file.writeAsBytesSync(bytes);
    mxLog("write file end");
    return file;
  }
}
