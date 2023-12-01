import 'package:bot_toast/bot_toast.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:image_merger_dart/blocs/base.dart';
import 'package:image_merger_dart/ui/pages/home.dart';
import 'package:image_merger_dart/ui/widgets/popup.dart';
import 'package:image_merger_dart/utils/disposable/state.dart';
import 'package:image_merger_dart/utils/disposable/stream.dart';
import 'package:starrail_ui/theme/colors.dart';

class App extends StatelessWidget {
  static final _defaultLightColorScheme =
      ColorScheme.fromSeed(seedColor: srHighlighted);
  static const _appBarTheme = AppBarTheme(
    iconTheme: IconThemeData(size: 16),
    color: Colors.transparent,
    centerTitle: true,
    elevation: 0,
    scrolledUnderElevation: 0,
    shadowColor: Colors.transparent,
    foregroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
  );

  const App({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightColorScheme, darkColorScheme) {
        ThemeData themeData = ThemeData(
          appBarTheme: _appBarTheme,
          colorScheme: lightColorScheme ?? _defaultLightColorScheme,
          // inputDecorationTheme: _inputDecorationTheme,
          fontFamily: "HYWH",
          textTheme: Theme.of(context).textTheme.apply(fontFamily: "HYWH"),
          useMaterial3: true,
        );
        return MaterialApp(
          title: '拼图',
          builder: BotToastInit(),
          navigatorObservers: [BotToastNavigatorObserver()],
          scrollBehavior: const _DefaultScrollBehavior(),
          theme: themeData,
          // darkTheme: themeData.copyWith(
          //   colorScheme: darkColorScheme ?? _defaultDarkColorScheme,
          // ),
          home: const HomePage(),
        );
      },
    );
  }
}

abstract class ThemedState<T extends StatefulWidget>
    extends DisposableState<T> {
  late final ThemeData themeData = Theme.of(context);
  late final ColorScheme colorScheme = themeData.colorScheme;

  void setupBloc(BaseBloc bloc) {
    bloc.loading.distinct().listen(Loading.on).cancelBy(disposeBag);
    bloc.errors.listen((error) {
      showSnackBar(context, error.toString());
    }).cancelBy(disposeBag);
  }
}

class _DefaultScrollBehavior extends ScrollBehavior {
  const _DefaultScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics();
}
