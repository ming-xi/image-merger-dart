import 'package:flutter/foundation.dart';
import 'package:image_merger_dart/utils/disposable/bloc.dart';
import 'package:image_merger_dart/utils/logger.dart';
import 'package:rxdart/rxdart.dart';

class BaseBloc extends DisposableBloc {
  final _errors = PublishSubject<dynamic>();
  final _loading = BehaviorSubject<bool>.seeded(false);
  BehaviorSubject<bool>? _notFound;

  Stream<dynamic> get errors => _errors.stream;

  ValueStream<bool> get loading => _loading.stream;

  ValueStream<bool> get isNotFound {
    assert(_notFound != null, 'Please enable "enableNotFound"');
    return _notFound!.stream;
  }

  BaseBloc();

  BaseBloc.enableNotFound() {
    enableNotFound();
  }

  @protected
  void setError(dynamic value, {StackTrace? stack}) {
    if (!_errors.isClosed) {
      logger.i("${runtimeType.toString()}: $value", error: "",stackTrace:  stack);
      _errors.add(value);
    }
  }

  @protected
  void setLoading(bool value) {
    if (!_loading.isClosed) {
      _loading.add(value);
    }
  }

  @protected
  void enableNotFound() {
    if (_loading.isClosed) return;
    _notFound ??= BehaviorSubject<bool>.seeded(false);
  }

  @protected
  bool checkNotFound(
    dynamic error, {
    bool Function(dynamic error)? customCheck,
  }) {
    if (_notFound != null && !_notFound!.isClosed) {
      final checked = (customCheck?.call(error)) ?? (false);
      if (checked) {
        _notFound!.add(true);
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _errors.close();
    _loading.close();
    _notFound?.close();
    super.dispose();
  }
}
