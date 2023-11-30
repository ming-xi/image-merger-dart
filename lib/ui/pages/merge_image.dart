import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_merger_dart/blocs/merge_image.dart';
import 'package:image_merger_dart/models/image.dart';
import 'package:image_merger_dart/ui/app.dart';
import 'package:image_merger_dart/ui/widgets/images.dart';
import 'package:image_merger_dart/utils/constants.dart';
import 'package:image_merger_dart/utils/image.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sprintf/sprintf.dart';
import 'package:starrail_ui/views/blur.dart';
import 'package:starrail_ui/views/buttons/normal.dart';
import 'package:starrail_ui/views/dialog.dart';
import 'package:starrail_ui/views/progress/slider.dart';
import 'package:starrail_ui/views/selectable/checkbox.dart';
import 'package:tuple/tuple.dart';

class MergeImagePage extends StatefulWidget {
  const MergeImagePage({super.key});

  @override
  State<MergeImagePage> createState() => _MergeImagePageState();
}

class _MergeImagePageState extends ThemedState<MergeImagePage> {
  final MergeImageBloc _bloc = MergeImageBloc();
  final _moving = BehaviorSubject<bool>.seeded(false);
  late final _movieModeStream = Rx.combineLatest(
    [
      _bloc.movieMode,
      _bloc.overlayOffsetStart,
      _bloc.overlayOffsetEnd,
    ],
    (values) => null,
  ).asBroadcastStream(onCancel: (subscription) => subscription.cancel());

  @override
  void initState() {
    super.initState();
    setupBloc(_bloc);
  }

  @override
  void dispose() {
    _bloc.dispose();
    _moving.close();
    super.dispose();
  }

  Future<Directory?> selectDir() async {
    String? path = await FilePicker.platform.getDirectoryPath();
    return path == null ? null : Directory(path);
  }

  Future<void> _saveResult({
    bool compatMode = false,
    bool multiThread = true,
  }) async {
    File? file;
    if (compatMode) {
      // file = await _bloc.saveImageCompat(context);
    } else {
      file = await _bloc.saveImage(context, multiThread: multiThread);
    }
    if (!mounted) {
      return;
    }
    if (file != null) {
      if (!isDesktop) {
        SRDialog.showMessage(
            context: context, title: "保存图片", message: "已保存到相册");
      } else {
        var directory = await selectDir();
        if (directory != null) {
          file = file.copySync(
              "${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg");
          SRDialog.showMessage(
              context: context, title: "保存图片", message: "已保存到：${file.path}");
        }
      }
    } else {
      SRDialog.showMessage(context: context, title: "保存图片", message: "出错了");
    }
  }

  Future<List<ImageUnit>> _showFileSourceMenu() async {
    return await SRDialog.showCustom(
          context: context,
          dialog: SRDialog.custom(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text("选择文件"),
                  onTap: () async =>
                      Navigator.of(context).pop(await _pickFiles()),
                ),
                ListTile(
                  title: const Text("剪贴板"),
                  onTap: () async {
                    if (await _clipboardHasImage) {
                      final imageBytes = await Pasteboard.image;
                      if (!mounted) {
                        return;
                      }
                      Navigator.of(context).pop([
                        if (imageBytes != null)
                          ImageUnit(bytes: imageBytes, fromFile: false)
                      ]);
                    } else if (await _clipboardHasFiles) {
                      var units = (await Pasteboard.files())
                          .map((e) {
                            try {
                              getImageSizeFromFile(File(e));
                              return File(e);
                            } catch (e) {
                              return null;
                            }
                          })
                          .whereNotNull()
                          .map((e) => ImageUnit(
                              bytes: e.readAsBytesSync(), fromFile: true))
                          .toList();
                      if (!mounted) {
                        return;
                      }
                      Navigator.of(context).pop(units);
                      if (units.isEmpty) {
                        SRDialog.showMessage(
                            context: context,
                            title: "无法添加",
                            message: "选中的文件都不是能识别的图片");
                      }
                    }
                  },
                )
              ],
            ),
          ),
        ) ??
        [];
  }

  void _showItemMenu(ImageUnit file) {
    var options = [
      Tuple2(
        "在上方插入",
        (popContext, index) async {
          List<ImageUnit> src = await _getInputFiles();
          if (src.isNotEmpty) {
            List<ImageUnit> files = _bloc.files.value;
            _insertImages(src, files.indexOf(file));
          }
          if (!mounted) {
            return;
          }
          Navigator.of(popContext).pop();
        },
      ),
      Tuple2(
        "在下方插入",
        (popContext, index) async {
          List<ImageUnit> src = await _getInputFiles();
          if (src.isNotEmpty) {
            List<ImageUnit> files = _bloc.files.value;
            _insertImages(src, files.indexOf(file) + 1);
          }
          if (!mounted) {
            return;
          }
          Navigator.of(popContext).pop();
        },
      ),
      Tuple2(
        "删除",
        (popContext, index) async {
          _removeImage(file);
          Navigator.of(popContext).pop();
        },
      ),
    ];
    SRDialog.showCustom(
      context: context,
      dialog: SRDialog.custom(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map(
                (e) => ListTile(
                  title: Text(e.item1),
                  onTap: () => e.item2(context, options.indexOf(e)),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Future<List<ImageUnit>> _getInputFiles() async {
    return (isDesktop && (await _clipboardAvailable))
        ? await _showFileSourceMenu()
        : await _pickFiles();
  }

  Future<bool> get _clipboardAvailable async =>
      (await _clipboardHasImage) || (await _clipboardHasFiles);

  Future<bool> get _clipboardHasImage async => (await Pasteboard.image) != null;

  Future<bool> get _clipboardHasFiles async {
    return (await Pasteboard.files()).isNotEmpty;
  }

  void _removeImage(ImageUnit file) => _bloc.removeFile(file.key);

  void _appendImages(List<ImageUnit> files) => _bloc.addFiles(files);

  void _insertImages(
    List<ImageUnit> files,
    int index,
  ) =>
      _bloc.addFiles(files, index: index);

  Future<List<ImageUnit>> _pickFiles() async {
    var list = await pickImages(
      context: context,
      checkForPermission: true,
    );
    return list.map((e) => ImageUnit.file(file: e)).toList();
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      color: colorScheme.background,
      child: child,
    );
  }

  Widget _buildContainer({required Widget child}) {
    return _buildCard(
      child: Container(
        constraints: const BoxConstraints(minHeight: 160),
        child: child,
      ),
    );
  }

  Widget _buildImage(int index, {bool cancelAlign = false}) {
    return StreamBuilder(
      stream: _movieModeStream,
      builder: (context, snapshot) {
        List<ImageUnit> files = _bloc.files.value;
        ImageUnit file = files[index];
        var startArray = _bloc.overlayOffsetStart.value;
        var endArray = _bloc.overlayOffsetEnd.value;
        var start = startArray[index];
        var end = max(startArray[index], endArray[index]);
        var imageSize = getImageSizeFromBytes(file.bytes);
        return GestureDetector(
          onLongPress: isDesktop
              ? null
              : () {
                  _showItemMenu(file);
                },
          onTap: !isDesktop
              ? null
              : () {
                  _showItemMenu(file);
                },
          child: _buildCard(
            child: (_bloc.movieMode.value && index > 0)
                ? ImageRegionWidget(
                    file: file,
                    topPercent: start,
                    bottomPercent: end,
                    imageSize: Size(
                      imageSize.$1.toDouble(),
                      imageSize.$2.toDouble(),
                    ),
                    onOffsetChanged: (double value) {
                      _bloc.setSpecificOverlayOffsetStart(
                        index,
                        clampDouble(start - value, 0, end),
                      );
                    },
                    onMoveStart: () {
                      _moving.add(true);
                    },
                    onMoveEnd: () {
                      _moving.add(false);
                    },
                  )
                : CustomImage.memory(
                    file.bytes,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildAdd() {
    return _buildContainer(
      child: Ink(
        child: InkWell(
          onTap: () async {
            var files = await _getInputFiles();
            if (files.isNotEmpty) {
              _appendImages(files);
            }
          },
          child: const Center(
            child: Icon(
              Icons.add_rounded,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return StreamBuilder(
      stream: _bloc.files,
      builder: (context, snapshot) {
        List<ImageUnit> files = _bloc.files.value;
        return StreamBuilder(
          stream: _movieModeStream,
          builder: (context, snapshot) {
            return StreamBuilder(
              stream: _moving,
              builder: (context, snapshot) {
                return ListView.builder(
                  physics: _moving.value
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  padding: MediaQuery.of(context).orientation ==
                          Orientation.landscape
                      ? const EdgeInsets.only(
                          top: 24,
                          left: 24,
                          right: 24,
                          bottom: 48,
                        )
                      : const EdgeInsets.only(
                          top: 48,
                          left: 24,
                          right: 24,
                          bottom: 48,
                        ),
                  itemBuilder: (context, index) {
                    if (index < files.length) {
                      return _buildImage(
                        index,
                        cancelAlign: index == files.length - 1,
                      );
                    } else {
                      return _buildAdd();
                    }
                  },
                  itemCount: files.length + 1,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildControls() {
    return StreamBuilder(
      stream: _movieModeStream,
      builder: (context, snapshot) {
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(24),
          child: SafeArea(
            top: MediaQuery.of(context).orientation == Orientation.landscape,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSlider(
                  title: "输出尺寸",
                  min: 0.1,
                  divisions: 20,
                  stream: _bloc.outputScale,
                  onChange: _bloc.setOutputScale,
                ),
                _buildSlider(
                  title: "输出质量",
                  min: 0.1,
                  divisions: 20,
                  stream: _bloc.outputQuality,
                  onChange: _bloc.setOutputQuality,
                ),
                Row(
                  children: [
                    SRCheckbox.auto(
                      context: context,
                      checked: _bloc.movieMode.value,
                      onChanged: (value) => _bloc.setMovieMode(value ?? false),
                    ),
                    const SizedBox(width: 8),
                    const Text("电影模式"),
                    const Spacer(),
                    SRButton.text(
                      highlightType: SRButtonHighlightType.highlighted,
                      onPress: () => _saveResult(multiThread: false),
                      text: "保存",
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: defaultAnimationDuration,
                  curve: defaultAnimationCurve,
                  child: SizedBox(
                    height: _bloc.movieMode.value ? null : 0,
                    child: StreamBuilder(
                      stream: _bloc.useUniqueOffset,
                      builder: (context, snapshot) {
                        bool useUniqueOffset = snapshot.data == true;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                SRCheckbox.auto(
                                  context: context,
                                  checked: useUniqueOffset,
                                  onChanged: useUniqueOffset
                                      ? null
                                      : (value) {
                                          _bloc.setUseUniqueOverlayOffset(
                                            true,
                                          );
                                        },
                                ),
                                const SizedBox(width: 8),
                                const Text("使用相同裁切位置"),
                                const Spacer(),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (useUniqueOffset)
                              _buildSlider(
                                title: "开始位置",
                                stream: _bloc.uniqueOverlayOffsetStart,
                                onChange: _bloc.setUniqueOverlayOffsetStart,
                              ),
                            if (useUniqueOffset)
                              _buildSlider(
                                title: "结束位置",
                                stream: _bloc.uniqueOverlayOffsetEnd,
                                onChange: _bloc.setUniqueOverlayOffsetEnd,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlider({
    required String title,
    required ValueStream<double> stream,
    required void Function(double value) onChange,
    double min = 0,
    double max = 1,
    int? divisions,
  }) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        var value = snapshot.data;
        if (value == null) {
          return const SizedBox.shrink();
        }
        return Row(
          children: [
            SizedBox(
              width: 100,
              child: Text("$title ${sprintf("%.0f%", [value * 100])}"),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SRSlider(
                value: value,
                onChanged: onChange,
                divisions: divisions,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Center(
            child: SRButton.circular(
          iconData: Icons.arrow_back_rounded,
          size: const Size.square(32),
          onPress: () => Navigator.of(context).pop(),
        )),
      ),
      extendBodyBehindAppBar: true,
      body: Builder(builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset("assets/images/back.jpg", fit: BoxFit.cover),
            ),
            Blurred(
              child: Builder(builder: (context) {
                if (MediaQuery.of(context).orientation ==
                    Orientation.landscape) {
                  return Row(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 300,
                        child: _buildControls(),
                      ),
                      Expanded(child: _buildList()),
                    ],
                  );
                } else {
                  return Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildList()),
                      _buildControls(),
                    ],
                  );
                }
              }),
            ),
          ],
        );
      }),
    );
  }
}
