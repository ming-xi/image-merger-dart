import 'package:flutter/widgets.dart';

import 'dispose_bag.dart';

abstract class DisposableState<T extends StatefulWidget> extends State<T> {
  final disposeBag = DisposeBag();

  @override
  void dispose() {
    disposeBag.dispose();
    super.dispose();
  }
}
