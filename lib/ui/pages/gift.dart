import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_merger_dart/blocs/gift.dart';
import 'package:image_merger_dart/models/gift.dart';
import 'package:image_merger_dart/ui/app.dart';
import 'package:image_merger_dart/ui/widgets/qr.dart';
import 'package:image_merger_dart/utils/constants.dart';
import 'package:image_merger_dart/utils/string.dart';
import 'package:rxdart/rxdart.dart';
import 'package:starrail_ui/views/base/squircle.dart';
import 'package:starrail_ui/views/blur.dart';
import 'package:starrail_ui/views/buttons/normal.dart';
import 'package:starrail_ui/views/dialog.dart';
import 'package:starrail_ui/views/input/text.dart';
import 'package:starrail_ui/views/misc/icon.dart';

class GiftPage extends StatefulWidget {
  const GiftPage({super.key});

  @override
  State<GiftPage> createState() => _GiftPageState();
}

class _GiftPageState extends ThemedState<GiftPage> {
  static const _shownItemsCount = 3;
  final GiftBloc _bloc = GiftBloc();
  final BehaviorSubject<double> _randomButtonRotationTurns =
      BehaviorSubject.seeded(0);
  late final _combinedStream =
      Rx.combineLatestList([_bloc.gifts, _bloc.selected]).asBroadcastStream(
    onCancel: (subscription) => subscription.cancel(),
  );

  final CarouselController _carouselController = CarouselController();
  final PageController _pageController = PageController(
    viewportFraction: 1 / _shownItemsCount,
  );
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _bloc.dispose();
    _pageController.dispose();
    _inputController.dispose();
    _inputNode.dispose();
    _randomButtonRotationTurns.close();
    super.dispose();
  }

  Widget _buildGift(Gift gift) {
    return GestureDetector(
      onTap: () => _carouselController.animateToPage(
        _bloc.gifts.value.indexOf(gift),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutQuart,
      ),
      child: Image.asset(
        gift.imagePath,
      ),
    );
  }

  Widget _buildButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: StreamBuilder(
          stream: _combinedStream,
          builder: (context, snapshot) {
            var gift = _bloc.gifts.value[_bloc.selected.value];
            return SRButton.text(
              highlightType: SRButtonHighlightType.highlighted,
              text:
                  "赞赏作者并送出一${gift.quantifier}${gift.name}（￥${gift.price.toPrice()}）",
              onPress: () {
                if (isDesktop) {
                  SRDialog.showCustom(
                      context: context,
                      dialog: SRDialog.custom(
                          child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    SmoothCornerBorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: QrCode(
                                  content: _bloc.alipayUrl,
                                  size: 200,
                                  background: Colors.transparent,),
                            ),
                            const SizedBox(height: 16),
                            const Text("请使用支付宝扫描"),
                          ],
                        ),
                      ),),);
                } else {
                  _bloc.confirmDonation();
                }
              },
            );
          },
        ),
      ),
    );
  }

  Padding _buildMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SRTextField(
              controller: _inputController,
              onChanged: _bloc.updateMessage,
              focusNode: _inputNode,
              maxLines: 5,
              hint: "捎句话给作者，注入正能量",
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder(
                stream: _randomButtonRotationTurns,
                builder: (context, snapshot) {
                  return AnimatedRotation(
                    turns: _randomButtonRotationTurns.value,
                    duration: defaultAnimationDuration * 1.5,
                    child: SRButton.circular(
                      size: const Size.square(36),
                      onPress: () {
                        _randomButtonRotationTurns
                            .add(_randomButtonRotationTurns.value + 1);
                        _bloc.useRandomMessage();
                        _inputController.text = _bloc.message.value;
                      },
                      child: const SRIcon(
                        iconData: Icons.refresh_rounded,
                        size: 24,
                        color: Colors.black,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 2),
              Text(
                "随机",
                style: themeData.textTheme.labelMedium
                    ?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGiftDes() {
    return SizedBox(
      width: double.infinity,
      child: StreamBuilder(
        stream: _combinedStream,
        builder: (context, snapshot) {
          var gifts = _bloc.gifts.value;
          return Text(
            "“${gifts[_bloc.selected.value].des}”",
            style: themeData.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          );
        },
      ),
    );
  }

  Widget _buildPager() {
    return StreamBuilder(
      stream: _combinedStream,
      builder: (context, snapshot) {
        var gifts = _bloc.gifts.value;
        var gift = gifts[_bloc.selected.value];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "如果此APP对你有帮助的话...请我${gift.verb}一${gift.quantifier}${gift.name}",
                  style: themeData.textTheme.bodyLarge
                      ?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                return Blurred(
                  child: Container(
                    color: colorScheme.primary.withOpacity(0.1),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: CarouselSlider(
                      carouselController: _carouselController,
                      items: gifts.map((e) => _buildGift(e)).toList(),
                      options: CarouselOptions(
                        height: constraints.maxWidth / _shownItemsCount,
                        viewportFraction: 1 / _shownItemsCount,
                        aspectRatio: 1,
                        onPageChanged: (index, reason) =>
                            _bloc.updateSelected(index),
                        pageSnapping: true,
                        enlargeCenterPage: true,
                        enlargeFactor: 0.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("赞赏作者"),
        leading: Center(
            child: SRButton.circular(
          iconData: Icons.arrow_back_rounded,
          size: const Size.square(32),
          onPress: () => Navigator.of(context).pop(),
        ),),
      ),
      extendBodyBehindAppBar: true,
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          gestureSettings: const DeviceGestureSettings(touchSlop: 48),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset("assets/images/back.jpg", fit: BoxFit.cover),
            ),
            Blurred(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 48),
                children: [
                  const SizedBox(height: kToolbarHeight + 16),
                  MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      gestureSettings:
                          const DeviceGestureSettings(touchSlop: kTouchSlop),
                    ),
                    child: _buildPager(),
                  ),
                  const SizedBox(height: 8),
                  _buildGiftDes(),
                  const SizedBox(height: 16),
                  _buildMessage(),
                  const SizedBox(height: 36),
                  _buildButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
