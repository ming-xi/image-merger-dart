import 'package:image_merger_dart/utils/logger.dart';
import 'package:sprintf/sprintf.dart';

const urlRegex =
    r"(https?|ftp|file):\/\/[-A-Za-z0-9+&@#\/%?=~_|!:,.;]+[\/-A-Za-z0-9+&@#\/%=~_|]*";
const emailRegex = r"^\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*";

String formatFileSize(int bytes) {
  if (bytes < 1024) {
    return "$bytes B";
  } else if (bytes < 1024 * 1024) {
    return sprintf("%.1f KB", [bytes / 1024]);
  } else if (bytes < 1024 * 1024 * 1024) {
    return sprintf("%.1f MB", [bytes / 1024 / 1024]);
  } else if (bytes < 1024 * 1024 * 1024 * 1024) {
    return sprintf("%.1f GB", [bytes / 1024 / 1024 / 1024]);
  } else {
    return sprintf("%.1f TB", [bytes / 1024 / 1024 / 1024 / 1024]);
  }
}

extension Price on int {
  String toPrice() {
    int count = 0;
    if (this % 10 != 0) {
      count = 2;
    } else if (this % 100 != 0) {
      count = 1;
    }
    return sprintf("%.${count}f", [this / 100]);
  }
}

int _timestamp = 0;

void mxLog(String message, {bool clear = false}) {
  DateTime time = DateTime.now();
  if (clear) {
    _timestamp = time.millisecondsSinceEpoch;
  }
  logger.i("[+ ${time.millisecondsSinceEpoch - _timestamp}ms] $message");
  _timestamp = time.millisecondsSinceEpoch;
}
