import 'dart:ui';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:starrail_ui/views/progress/circular.dart';
import 'package:tuple/tuple.dart';

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

typedef PopupCallback = void Function(BuildContext context);

class CardPopup extends StatefulWidget {
  static const double _outerPadding = 16;

  final String? title;
  final String? message;
  final Widget? customWidget;
  final bool dismissOnTouchOutside;
  final EdgeInsets? customWidgetMargin;
  final String? primaryActionText;
  final String? secondaryActionText;
  final PopupCallback? primaryAction;
  final PopupCallback? secondaryAction;

  const CardPopup({
    super.key,
    this.title,
    this.message,
    this.customWidget,
    this.customWidgetMargin,
    required this.dismissOnTouchOutside,
    this.primaryAction,
    this.secondaryAction,
    this.primaryActionText,
    this.secondaryActionText,
  }) : assert(message != null || customWidget != null);

  static Future<T?> showPermission<T>(
    BuildContext context, {
    String? message,
  }) async {
    return await CardPopup.show(
      context,
      title: "权限不足",
      message: message,
      primaryActionText: "打开设置",
      primaryAction: (context) {
        openAppSettings().catchError((error) => true);
        Navigator.pop(context);
      },
    );
  }

  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    String? message,
    bool dismissOnTouchOutside = true,
    String? primaryActionText,
    PopupCallback? primaryAction,
    String? secondaryActionText,
    PopupCallback? secondaryAction,
  }) {
    return _showBlurBackgroundDialog(
      context,
      dismissOnTouchOutside,
      (context) => CardPopup(
        title: title,
        message: message,
        dismissOnTouchOutside: dismissOnTouchOutside,
        primaryAction: primaryAction,
        primaryActionText: primaryActionText,
        secondaryAction: secondaryAction,
        secondaryActionText: secondaryActionText,
      ),
    );
  }

  static Future<T?> showCustom<T>(
    BuildContext context, {
    String? title,
    Widget? customWidget,
    bool dismissOnTouchOutside = true,
  }) {
    return _showBlurBackgroundDialog(
      context,
      dismissOnTouchOutside,
      (context) => CardPopup(
        title: title,
        customWidget: customWidget,
        dismissOnTouchOutside: dismissOnTouchOutside,
      ),
    );
  }

  static Future<T?> showOptionList<T>(
    BuildContext context, {
    String? title,
    required List<Tuple2<String, Function(BuildContext context, int index)>>
        options,
    bool dismissOnTouchOutside = true,
  }) {
    return _showBlurBackgroundDialog(
      context,
      dismissOnTouchOutside,
      (popContext) => CardPopup(
        title: title,
        customWidgetMargin: EdgeInsets.zero,
        customWidget: Material(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map(
                  (e) => ListTile(
                    title: Text(e.item1),
                    onTap: () => e.item2(popContext, options.indexOf(e)),
                  ),
                )
                .toList(),
          ),
        ),
        dismissOnTouchOutside: dismissOnTouchOutside,
      ),
    );
  }

  static Future<T?> _showBlurBackgroundDialog<T>(
    BuildContext context,
    bool dismissOnTouchOutside,
    CardPopup Function(BuildContext context) builder,
  ) {
    //use WillPopScope to prevent dismiss dialog by pressing
    //back button on Android devices
    return showGeneralDialog<T>(
      context: context,
      barrierLabel: "",
      barrierDismissible: dismissOnTouchOutside,
      barrierColor: Colors.black.withOpacity(0.25),
      pageBuilder: (ctx, anim1, anim2) => WillPopScope(
        child: builder(context),
        onWillPop: () => Future.value(dismissOnTouchOutside),
      ),
      transitionBuilder: (ctx, anim1, anim2, child) => BackdropFilter(
        filter:
            ImageFilter.blur(sigmaX: 8 * anim1.value, sigmaY: 8 * anim1.value),
        child: FadeTransition(
          opacity: anim1,
          child: child,
        ),
      ),
    );
  }

  @override
  State<CardPopup> createState() => _CardPopupState();
}

class _CardPopupState extends State<CardPopup> {
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  Widget buildDefaultMessage(String message) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            message,
            style: _textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    if (widget.dismissOnTouchOutside && widget.title == null) {
      //if no title and close button hidden
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              top: 26 - CardPopup._outerPadding,
              left: 28 - CardPopup._outerPadding,
              right: widget.dismissOnTouchOutside
                  ? 28 - CardPopup._outerPadding
                  : 8,
              bottom: 20,
            ),
            child: Text(
              widget.title ?? "",
              style: _textTheme.titleLarge,
            ),
          ),
        ),
        Visibility(
          visible: !widget.dismissOnTouchOutside,
          child: _buildCloseButton(context),
        )
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (widget.customWidget == null) {
      return Padding(
        padding: const EdgeInsets.only(
          left: 28 - CardPopup._outerPadding,
          right: 28 - CardPopup._outerPadding,
          bottom: 32 - CardPopup._outerPadding,
        ),
        child: buildDefaultMessage(widget.message ?? ""),
      );
    } else {
      return Padding(
        padding: widget.customWidgetMargin ??
            const EdgeInsets.only(
              left: 28 - CardPopup._outerPadding,
              right: 28 - CardPopup._outerPadding,
              bottom: 32 - CardPopup._outerPadding,
            ),
        child: widget.customWidget,
      );
    }
  }

  List<Widget> _buildActionButtons(BuildContext context) {
    return [
      if (widget.secondaryAction != null)
        _buildActionButton(widget.secondaryActionText ?? "", () {
          widget.secondaryAction!(context);
        }),
      if (widget.primaryAction != null)
        _buildActionButton(widget.primaryActionText ?? "", () {
          widget.primaryAction!(context);
        }),
    ];
  }

  Widget _buildActionButton(String text, Function() onTap) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        text,
        style: _textTheme.bodyLarge,
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return IconButton(
      onPressed: () => Navigator.of(context).pop(),
      icon: const Icon(Icons.close_rounded),
    );
  }

  Widget _buildContent(BuildContext context) {
    var children = [
      _buildHeader(context),
      _buildBody(context),
    ];
    List<Widget> buttons = _buildActionButtons(context);

    if (buttons.isNotEmpty) {
      buttons = buttons
          .expand(
            (e) => [
              e,
              const SizedBox(
                width: 8,
              )
            ],
          )
          .toList()
        ..removeLast();
      children.addAll([
        Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [const Spacer(), ...buttons],
        )
      ]);
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(CardPopup._outerPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _CenterModalContainer(child: _buildContent(context));
  }
}

class _CenterModalContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;
  final BorderRadiusGeometry? borderRadius;

  const _CenterModalContainer({
    Key? key,
    required this.child,
    this.padding,
    this.constraints,
    this.borderRadius,
  }) : super(key: key);

  Map<String, double> _getConstraints(BuildContext context) {
    final MediaQueryData? data = MediaQuery.maybeOf(context);
    double bottomPadding = 0;
    double maxWidth = 343;
    double maxHeight = 500;
    if (data != null) {
      if (data.viewInsets.bottom > 0) {
        bottomPadding = data.viewInsets.bottom;
      }
      if (data.size.width <= (maxWidth + 40)) {
        maxWidth = data.size.width - 40;
      }
      if (data.size.height <= (maxHeight + 40)) {
        maxHeight = data.size.height - 40;
      }
    }
    return {
      "bottomPadding": bottomPadding,
      "maxWidth": maxWidth,
      "maxHeight": maxHeight,
    };
  }

  @override
  Widget build(BuildContext context) {
    final data = _getConstraints(context);
    final bottomPadding = data['bottomPadding']!;
    final maxWidth = data['maxWidth']!;
    final maxHeight = data['maxHeight']!;
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          margin: EdgeInsets.only(bottom: bottomPadding),
          padding: padding,
          width: maxWidth,
          constraints: constraints ?? BoxConstraints(maxHeight: maxHeight),
          child: child,
        ),
      ),
    );
  }
}
