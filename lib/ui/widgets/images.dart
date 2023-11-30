import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_merger_dart/models/image.dart';
import 'package:image_merger_dart/utils/constants.dart';
import 'package:image_merger_dart/utils/logger.dart';
import 'package:image_picker/image_picker.dart';
import 'package:images_picker/images_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';
import 'package:starrail_ui/views/buttons/normal.dart';
import 'package:starrail_ui/views/dialog.dart';
import 'package:tuple/tuple.dart';

final ImagePicker _picker = ImagePicker();

class ImageRegionWidget extends StatefulWidget {
  final ImageUnit file;
  final double topPercent;
  final double bottomPercent;
  final Size imageSize;

  final VoidCallback onMoveStart;
  final VoidCallback onMoveEnd;
  final ValueChanged<double> onOffsetChanged;

  const ImageRegionWidget({
    super.key,
    required this.file,
    required this.topPercent,
    required this.bottomPercent,
    required this.imageSize,
    required this.onMoveStart,
    required this.onMoveEnd,
    required this.onOffsetChanged,
  });

  @override
  State<ImageRegionWidget> createState() => _ImageRegionWidgetState();
}

class _ImageRegionWidgetState extends State<ImageRegionWidget> {
  final _tempOffset = BehaviorSubject<double>.seeded(0);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _tempOffset.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _tempOffset,
      builder: (context, snapshot) {
        return LayoutBuilder(
          builder: (context, constraints) {
            var width = constraints.maxWidth;
            var height = constraints.maxWidth /
                widget.imageSize.width *
                widget.imageSize.height;
            var top = widget.topPercent - _tempOffset.value;
            var croppedHeight = height * (widget.bottomPercent - top);
            return SizedOverflowBox(
              size: Size(width, croppedHeight),
              alignment: Alignment.topCenter,
              child: Transform.translate(
                offset: Offset(0, -(height * top)),
                child: ClipRect(
                  clipper: ImageClipper(
                    topPercent: top,
                    bottomPercent: widget.bottomPercent,
                  ),
                  child: Stack(
                    children: [
                      Image.memory(
                        widget.file.bytes,
                        width: width,
                        height: height,
                        fit: BoxFit.fill,
                      ),
                      Positioned(
                          bottom: 4 + height * (1 - widget.bottomPercent),
                          right: 4,
                          child: _MoveButton(
                            imageSize: widget.imageSize,
                            width: width,
                            baseOffsetStart: top,
                            baseOffsetEnd: widget.bottomPercent,
                            onOffsetChanged: (value) {
                              _tempOffset.add(value);
                            },
                            onMoveStart: widget.onMoveStart,
                            onMoveEnd: () {
                              widget.onOffsetChanged(_tempOffset.value);
                              _tempOffset.add(0);
                              widget.onMoveEnd();
                            },
                          ))
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MoveButton extends StatefulWidget {
  final Size imageSize;
  final double width;
  final double baseOffsetStart;
  final double baseOffsetEnd;
  final VoidCallback onMoveStart;
  final VoidCallback onMoveEnd;
  final ValueChanged<double> onOffsetChanged;

  const _MoveButton({
    super.key,
    required this.imageSize,
    required this.width,
    required this.baseOffsetStart,
    required this.baseOffsetEnd,
    required this.onMoveStart,
    required this.onMoveEnd,
    required this.onOffsetChanged,
  });

  @override
  State<_MoveButton> createState() => _MoveButtonState();
}

class _MoveButtonState extends State<_MoveButton> {
  double? _start;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        _start = event.position.dy;
        widget.onMoveStart();
      },
      onPointerMove: (event) {
        var imageHeight =
            widget.width / (widget.imageSize.width / widget.imageSize.height);
        widget.onOffsetChanged((event.position.dy - _start!) / imageHeight);
      },
      onPointerUp: (event) {
        widget.onMoveEnd();
      },
      child: Container(
        width: 30,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.25),
                spreadRadius: 2,
                blurRadius: 4,
                offset: const Offset(0, 1))
          ],
        ),
        child: const Icon(
          Icons.reorder_rounded,
          size: 16,
        ),
      ),
    );
  }
}

class ImageClipper extends CustomClipper<Rect> {
  final double topPercent;
  final double bottomPercent;

  ImageClipper({
    required this.topPercent,
    required this.bottomPercent,
  });

  @override
  Rect getClip(Size size) {
    const left = 0.0;
    final top = topPercent * size.height;
    final right = size.width;
    final bottom = bottomPercent * size.height;
    return Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  bool shouldReclip(ImageClipper oldClipper) {
    return topPercent != oldClipper.topPercent ||
        bottomPercent != oldClipper.bottomPercent;
  }
}

Future<bool> saveImageToGallery(File file) async {
  return ImagesPicker.saveImageToAlbum(file);
}

Future<bool> checkPermission({BuildContext? context, String? title}) async {
  try {
    Permission permission = (Platform.isIOS ||
            (Platform.isAndroid &&
                (await DeviceInfoPlugin().androidInfo).version.sdkInt >= 33))
        ? Permission.photos
        : Permission.storage;
    PermissionStatus status = await permission.status;
    if (!status.isGranted) {
      status = await permission.request();
    }
    if (!status.isGranted) {
      if (context != null && context.mounted) {
        SRDialog.showCustom(
          context: context,
          dialog: SRDialog.custom(
              child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title ?? "权限不足"),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SRButton.text(
                      highlightType: SRButtonHighlightType.highlighted,
                      text: "打开设置",
                      onPress: () {
                        openAppSettings().catchError((error) => true);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                )
              ],
            ),
          )),
        );
      }
      return false;
    }
    return true;
  } catch (error) {
    logger.i('check Photos read permission error: $error');
    return false;
  }
}

Future<List<File>> pickImages({
  BuildContext? context,
  bool? checkForPermission,
  double? maxHeight,
  int imageQuality = 100,
  bool requestFullMetadata = false,
}) async {
  if (!isDesktop) {
    final isGranted = checkForPermission == true
        ? await checkPermission(context: context, title: "本程序需要相册权限以选择图片")
        : true;
    if (!isGranted) {
      return [];
    }
  }
  try {
    List<File> files;
    var xFiles = await _picker.pickMultiImage(
      imageQuality: imageQuality,
      requestFullMetadata: requestFullMetadata,
      maxHeight: maxHeight,
    );
    files = xFiles.map((e) => File(e.path)).toList();
    logger.d('picked images: ${files.map((e) => e.path).toList()}');
    return files;
  } catch (error) {
    logger.i('pick image error: $error');
    return [];
  }
}

class CustomImage extends StatelessWidget {
  final String imageUrl;
  final Uint8List? bytes;
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit fit;
  final Alignment alignment;
  final ImageRepeat repeat;
  final FilterQuality filterQuality;
  final PlaceholderWidgetBuilder? placeholder;

  const CustomImage({
    Key? key,
    String? imageUrl,
    this.bytes,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.filterQuality = FilterQuality.low,
    this.placeholder,
  })  : assert(imageUrl != null || bytes != null),
        imageUrl = imageUrl ?? '',
        super(key: key);

  const CustomImage.asset(
    String name, {
    Key? key,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.filterQuality = FilterQuality.low,
    this.placeholder,
  })  : imageUrl = name,
        bytes = null,
        super(key: key);

  const CustomImage.network(
    String src, {
    Key? key,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.filterQuality = FilterQuality.low,
    this.placeholder,
  })  : imageUrl = src,
        bytes = null,
        super(key: key);

  const CustomImage.memory(
    Uint8List this.bytes, {
    Key? key,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.filterQuality = FilterQuality.low,
    this.placeholder,
  })  : imageUrl = '',
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return _CustomImage(
      imageUrl: imageUrl,
      bytes: bytes,
      width: width,
      height: height,
      color: color,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      filterQuality: filterQuality,
      placeholder: placeholder,
    );
  }
}

class RoundedRectangleImage extends CustomImage {
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;
  final List<BoxShadow>? shadows;
  final Clip clip;

  Color get _backgroundColor => backgroundColor ?? Colors.white;

  bool get _disableBox =>
      borderWidth == 0 &&
      backgroundColor == null &&
      margin == null &&
      padding == null &&
      constraints == null &&
      shadows == null;

  const RoundedRectangleImage({
    Key? key,
    required String imageUrl,
    this.borderWidth = 2,
    this.borderColor = Colors.black,
    this.borderRadius = 8,
    this.backgroundColor,
    this.margin,
    this.padding,
    this.constraints,
    this.shadows,
    this.clip = Clip.hardEdge,
    Uint8List? bytes,
    double? width,
    double? height,
    Color? color,
    BoxFit fit = BoxFit.cover,
    Alignment alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    FilterQuality filterQuality = FilterQuality.low,
  }) : super(
          key: key,
          imageUrl: imageUrl,
          bytes: bytes,
          width: width,
          height: height,
          color: color,
          fit: fit,
          alignment: alignment,
          repeat: repeat,
          filterQuality: filterQuality,
        );

  const RoundedRectangleImage.memory({
    Key? key,
    required Uint8List bytes,
    this.borderWidth = 2,
    this.borderColor = Colors.black,
    this.borderRadius = 8,
    this.backgroundColor,
    this.margin,
    this.padding,
    this.constraints,
    this.shadows,
    this.clip = Clip.hardEdge,
    double? width,
    double? height,
    Color? color,
    BoxFit fit = BoxFit.cover,
    Alignment alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    FilterQuality filterQuality = FilterQuality.low,
  }) : super.memory(
          bytes,
          key: key,
          width: width,
          height: height,
          color: color,
          fit: fit,
          alignment: alignment,
          repeat: repeat,
          filterQuality: filterQuality,
        );

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      clipBehavior: clip,
      borderRadius: BorderRadius.circular(borderRadius - borderWidth),
      child: super.build(context),
    );
    if (!_disableBox) {
      return Container(
        margin: margin,
        padding: padding,
        constraints: constraints,
        clipBehavior: clip,
        decoration: borderWidth > 0
            ? ShapeDecoration(
                color: _backgroundColor,
                shadows: shadows,
                shape: RoundedRectangleBorder(
                  side: BorderSide(width: borderWidth, color: borderColor),
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
              )
            : BoxDecoration(
                color: _backgroundColor,
                boxShadow: shadows,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
        child: image,
      );
    }
    return image;
  }
}

class CircleImage extends CustomImage {
  final Color borderColor;
  final double borderWidth;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;
  final List<BoxShadow>? shadows;
  final Clip clip;

  Color get _backgroundColor => backgroundColor ?? Colors.white;

  bool get _disableBox =>
      borderWidth == 0 &&
      backgroundColor == null &&
      margin == null &&
      padding == null &&
      constraints == null &&
      shadows == null;

  const CircleImage({
    Key? key,
    required String imageUrl,
    this.borderWidth = 2,
    this.borderColor = Colors.black,
    this.backgroundColor,
    this.margin,
    this.padding,
    this.constraints,
    this.shadows,
    this.clip = Clip.hardEdge,
    Uint8List? bytes,
    double? width,
    double? height,
    Color? color,
    BoxFit fit = BoxFit.cover,
    Alignment alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    FilterQuality filterQuality = FilterQuality.low,
  }) : super(
          key: key,
          imageUrl: imageUrl,
          bytes: bytes,
          width: width,
          height: height,
          color: color,
          fit: fit,
          alignment: alignment,
          repeat: repeat,
          filterQuality: filterQuality,
        );

  const CircleImage.memory({
    Key? key,
    required Uint8List bytes,
    this.borderWidth = 2,
    this.borderColor = Colors.black,
    this.backgroundColor,
    this.margin,
    this.padding,
    this.constraints,
    this.shadows,
    this.clip = Clip.hardEdge,
    double? width,
    double? height,
    Color? color,
    BoxFit fit = BoxFit.cover,
    Alignment alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    FilterQuality filterQuality = FilterQuality.low,
  }) : super.memory(
          bytes,
          key: key,
          width: width,
          height: height,
          color: color,
          fit: fit,
          alignment: alignment,
          repeat: repeat,
          filterQuality: filterQuality,
        );

  @override
  Widget build(BuildContext context) {
    final image = ClipOval(
      clipBehavior: clip,
      child: super.build(context),
    );
    if (!_disableBox) {
      return Container(
        margin: margin,
        padding: padding,
        constraints: constraints,
        clipBehavior: clip,
        decoration: borderWidth > 0
            ? ShapeDecoration(
                color: _backgroundColor,
                shadows: shadows,
                shape: CircleBorder(
                  side: BorderSide(width: borderWidth, color: borderColor),
                ),
              )
            : BoxDecoration(
                color: _backgroundColor,
                boxShadow: shadows,
                shape: BoxShape.circle,
              ),
        child: image,
      );
    }
    return image;
  }
}

class _CustomImage extends StatelessWidget {
  final String imageUrl;
  final Uint8List? bytes;
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit fit;
  final Alignment alignment;
  final ImageRepeat repeat;
  final FilterQuality filterQuality;
  final PlaceholderWidgetBuilder? placeholder;
  late final _CacheConstraint _cacheConstraint;

  _CustomImage({
    Key? key,
    String? imageUrl,
    this.bytes,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.filterQuality = FilterQuality.low,
    this.placeholder,
  })  : assert(imageUrl != null || bytes != null),
        imageUrl = imageUrl ?? '',
        super(key: key) {
    _cacheConstraint = _CacheConstraint(width: width, height: height);
  }

  bool get isSvg => imageUrl.endsWith('.svg');

  bool get isAsset => imageUrl.startsWith('assets/');

  bool get isFile => imageUrl.startsWith('/');

  Tuple2<int?, int?>? get memSize => _cacheConstraint.memSize;

  Widget get placeholderBox {
    if (width != null || height != null) {
      return SizedBox(
        width: width,
        height: height,
        child: color != null ? ColoredBox(color: color!) : null,
      );
    }
    return const SizedBox.shrink();
  }

  Widget get svgImage {
    if (isAsset) {
      return SvgPicture.asset(
        imageUrl,
        width: width,
        height: height,
        colorFilter:
            color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
        fit: fit,
        alignment: alignment,
        placeholderBuilder: (context) => placeholder != null
            ? placeholder!(context, imageUrl)
            : placeholderBox,
        // repeat: repeat,
        // filterQuality: filterQuality,
      );
    }
    if (isFile) {
      return SvgPicture.file(
        File(imageUrl),
        width: width,
        height: height,
        colorFilter:
            color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
        fit: fit,
        alignment: alignment,
        placeholderBuilder: (context) => placeholder != null
            ? placeholder!(context, imageUrl)
            : placeholderBox,
        // repeat: repeat,
        // filterQuality: filterQuality,
      );
    }
    return SvgPicture.network(
      imageUrl,
      width: width,
      height: height,
      colorFilter:
          color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
      fit: fit,
      alignment: alignment,
      placeholderBuilder: (context) => placeholder != null
          ? placeholder!(context, imageUrl)
          : placeholderBox,
      // repeat: repeat,
      // filterQuality: filterQuality,
    );
  }

  Widget get localImage {
    if (isAsset) {
      return Image.asset(
        imageUrl,
        width: width,
        height: height,
        color: color,
        fit: fit,
        alignment: alignment,
        repeat: repeat,
        filterQuality: filterQuality,
        cacheWidth: memSize?.item1,
        cacheHeight: memSize?.item2,
        errorBuilder: (context, error, stackTrace) => placeholderBox,
      );
    }
    if (isFile) {
      return Image.file(
        File(imageUrl),
        width: width,
        height: height,
        color: color,
        fit: fit,
        alignment: alignment,
        repeat: repeat,
        filterQuality: filterQuality,
        cacheWidth: memSize?.item1,
        cacheHeight: memSize?.item2,
        errorBuilder: (context, error, stackTrace) => placeholderBox,
      );
    }
    return Image.memory(
      bytes!,
      width: width,
      height: height,
      color: color,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      filterQuality: filterQuality,
      errorBuilder: (context, error, stackTrace) => placeholderBox,
      cacheWidth: memSize?.item1,
      cacheHeight: memSize?.item2,
    );
  }

  Widget get networkImage {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      color: color,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      filterQuality: filterQuality,
      memCacheWidth: memSize?.item1,
      memCacheHeight: memSize?.item2,
      maxWidthDiskCache: _cacheConstraint.maxDiskCache,
      maxHeightDiskCache: _cacheConstraint.maxDiskCache,
      fadeOutDuration: const Duration(milliseconds: 250),
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (context, url) =>
          placeholder != null ? placeholder!(context, url) : placeholderBox,
      errorWidget: (context, url, error) => placeholderBox,
    );
  }

  Widget get image {
    if (isSvg) {
      return svgImage;
    } else if (bytes != null || isAsset || isFile) {
      return localImage;
    }
    return networkImage;
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty && bytes == null) {
      return placeholderBox;
    }
    _cacheConstraint._constraint(context, newWidth: width, newHeight: height);

    if (_cacheConstraint.enableDefault) {
      return LayoutBuilder(
        builder: (_, constraint) {
          _cacheConstraint._defaultConstraint(context, constraint);
          return image;
        },
      );
    }
    return image;
  }
}

class _CacheConstraint {
  final int maxDiskCache;
  final double? width;
  final double? height;

  Tuple2<int?, int?>? _current;
  Tuple2<int?, int?>? _default;
  double? _maxWidth;
  double? _screenWidth;
  double? _devicePixelRatio;
  bool _enableDefault;

  _CacheConstraint({this.width, this.height})
      : maxDiskCache = 1500,
        _current = null,
        _enableDefault =
            ((width == null || width == 0) && (height == null || height == 0)),
        _default = null,
        _maxWidth = null,
        _screenWidth = null,
        _devicePixelRatio = null;

  double _getPixelRatio(double? devicePixelRatio) {
    devicePixelRatio ??= 1;
    if (devicePixelRatio >= 4) {
      devicePixelRatio = 4;
    } else if (devicePixelRatio <= 1) {
      devicePixelRatio = 1;
    }
    return devicePixelRatio;
  }

  void _constraint(
    BuildContext context, {
    double? newWidth,
    double? newHeight,
  }) {
    if (_current != null && newWidth == width && newHeight == height) {
      return;
    }
    _enableDefault = ((newWidth == null || newWidth == 0) &&
        (newHeight == null || newHeight == 0));
    int? memWidth;
    int? memHeight;
    double validWidth = width ?? 0;
    double validHeight = width ?? 0;

    if (_screenWidth == null || _screenWidth == 0) {
      final data = MediaQuery.maybeOf(context);
      _screenWidth = data?.size.width ?? 0;
      _devicePixelRatio = data?.devicePixelRatio ?? 1;
    }

    if (validWidth > 0 || validHeight > 0) {
      final pixelRatio = _getPixelRatio(_devicePixelRatio);
      if (validWidth >= validHeight) {
        memWidth = (validWidth * pixelRatio).toInt();
        memWidth = memWidth >= maxDiskCache ? maxDiskCache : memWidth;
      } else {
        memHeight = (validHeight * pixelRatio).toInt();
        memHeight = memHeight >= maxDiskCache ? maxDiskCache : memHeight;
      }
    }
    _current = Tuple2(memWidth, memHeight);
  }

  void _defaultConstraint(
    BuildContext context,
    BoxConstraints constraints, {
    bool enableRefresh = false,
  }) {
    final double newMax =
        constraints.maxWidth != double.infinity ? constraints.maxWidth : 0;
    if (_screenWidth == null || _screenWidth == 0) {
      final data = MediaQuery.maybeOf(context);
      _screenWidth = data?.size.width ?? 0;
      _devicePixelRatio = data?.devicePixelRatio ?? 1;
    }
    if (_default != null && (!enableRefresh || _maxWidth == newMax)) {
      return;
    }

    _maxWidth = newMax;
    final pixelRatio = _getPixelRatio(_devicePixelRatio);
    final width = _screenWidth! > 0
        ? _screenWidth! > newMax
            ? newMax > 0
                ? newMax * pixelRatio
                : _screenWidth!
            : _screenWidth!
        : 0.0;

    int? memWidth = width > 0
        ? width >= maxDiskCache
            ? maxDiskCache
            : width.toInt()
        : null;

    _default = Tuple2(memWidth, null);
  }

  Tuple2<int?, int?>? get memSize {
    if (!_enableDefault) {
      return _current;
    }
    final cacheWidth =
        _current?.item1 ?? (_current?.item2 == null ? _default?.item1 : null);
    final cacheHeight =
        _current?.item2 ?? (_current?.item1 == null ? _default?.item2 : null);
    if (_current?.item1 == cacheWidth && _current?.item2 == cacheHeight) {
      return _current;
    }

    return Tuple2(cacheWidth, cacheHeight);
  }

  bool get enableDefault => _enableDefault;
}
