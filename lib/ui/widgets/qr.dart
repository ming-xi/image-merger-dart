import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCode extends StatelessWidget {
  final String content;
  final Color background;
  final Color foreground;
  final double size;

  const QrCode({
    super.key,
    required this.content,
    this.background = Colors.white,
    this.foreground = Colors.black,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      data: content,
      size: size,
      backgroundColor: background,
      eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: foreground),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.circle,
        color: foreground,
      ),
      errorStateBuilder: (c, e) => const SizedBox.shrink(),
    );
  }
}
