import 'dart:io';

import 'package:flutter/animation.dart';

const Duration defaultAnimationDuration = Duration(milliseconds: 250);
const Curve defaultAnimationCurve = Curves.easeOutCubic;
final isDesktop = Platform.isMacOS || Platform.isWindows;
