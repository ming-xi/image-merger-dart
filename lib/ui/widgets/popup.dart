import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:starrail_ui/views/progress/circular.dart';

class Loading {
  static void on(bool loading) {
    loading ? show() : dismiss();
  }

  static void show() {
    BotToast.showCustomLoading(
      toastBuilder: (_) => const SRLoading(),
      backgroundColor: Colors.black.withOpacity(0.75),
      allowClick: true,
    );
  }

  static void dismiss() {
    BotToast.closeAllLoading();
  }
}

void showSnackBar(BuildContext context, String message) {
  final snackBar = SnackBar(
    duration: const Duration(seconds: 2),
    content: Text(message),
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
