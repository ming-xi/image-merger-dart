// ignore_for_file: require_trailing_commas

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';


Logger logger = Logger(
    printer: CustomPrinter(),
    level: kDebugMode ? Level.verbose : Level.info,
    filter: ProductionFilter());

class CustomPrinter extends LogPrinter {
  static final levelPrefixes = {
    Level.verbose: '[V]',
    Level.debug: '[D]',
    Level.info: '[I]',
    Level.warning: '[W]',
    Level.error: '[E]',
    Level.wtf: '[WTF]',
  };

  static final levelColors = {
    Level.verbose: AnsiColor.fg(AnsiColor.grey(0.5)),
    Level.debug: const AnsiColor.none(),
    Level.info: const AnsiColor.fg(12),
    Level.warning: const AnsiColor.fg(208),
    Level.error: const AnsiColor.fg(196),
    Level.wtf: const AnsiColor.fg(199),
  };

  CustomPrinter();

  @override
  List<String> log(LogEvent event) {
    var messageStr = _stringifyMessage(event.message);
    var errorStr = event.error != null ? '  ERROR: ${event.error}' : '';
    AnsiColor color = CustomPrinter.levelColors[event.level]!;
    return [(color('$messageStr$errorStr'))];
  }

  String _stringifyMessage(dynamic message) {
    final finalMessage = message is Function ? message() : message;
    if (finalMessage is Map || finalMessage is Iterable) {
      var encoder = const JsonEncoder.withIndent(null);
      return encoder.convert(finalMessage);
    } else {
      return finalMessage.toString();
    }
  }
}
