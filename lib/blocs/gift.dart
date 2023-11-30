import 'dart:convert';
import 'dart:math';

import 'package:image_merger_dart/models/gift.dart';
import 'package:image_merger_dart/utils/string.dart';
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'base.dart';

class GiftBloc extends BaseBloc {
  static const _messages = [
    "你开发的拼图app真是太棒了！免费的、无限制输入图片数量，UI界面简洁清爽，拼图速度超快！而且你还考虑到了输出原尺寸结果图，辛苦你了！感谢你为我们带来了如此实用的工具！",
    "大赞给辛勤劳动的开发者！你的拼图app真的太给力了！免费使用，无限制输入图片数量，UI界面简洁漂亮，拼图速度惊人！感谢你为我们带来了如此便捷的拼图体验！",
    "感谢你的辛勤付出，你开发的拼图app真是解决了我的大问题！免费、无限制输入图片数量，UI界面简洁清爽，拼图速度超快！还能输出无损原尺寸结果图，你的努力没有白费！",
    "开发者大大辛苦了！你的拼图app真是太赞了！免费使用，无限制输入图片数量，UI界面简洁漂亮，拼图速度惊人！感谢你为我们带来了如此优秀的工具！",
    "无限点赞给辛勤的开发者！你开发的拼图app真的太棒了！免费、无限制输入图片数量，UI界面简洁清爽，拼图速度超快！你的辛勤努力让我们的拼图体验变得更加轻松愉快！",
    "大大辛苦了！你开发的拼图app真的太赞了！免费使用，无限制输入图片数量，UI界面简洁漂亮，拼图速度惊人！感谢你为我们带来了如此出色的拼图工具！",
    "你真是太棒了！你的app完美解决了我的问题！免费使用，无限制输入图片数量，UI简洁又清爽，拼图速度快得惊人！还能输出无损原尺寸结果图，你的努力让我们的拼图体验更上一层楼！",
    "非常感谢你开发这么优秀的拼图app！免费、无限制输入图片数量，UI界面简洁漂亮，拼图速度超快！你的努力和才华让我们拥有了如此出色的工具，辛苦你了！",
    "作为用户，我必须向你致敬，开发者！你的拼图app真是太给力了！免费使用，无限制输入图片数量，UI界面简洁清爽，拼图速度快得让人惊叹！感谢你为我们创造了这么实用的工具！",
    "开发者大大辛苦了！你的拼图app真的太赞了！免费、无限制输入图片数量，UI界面简洁漂亮，拼图速度快得让人惊艳！感谢你的辛勤努力，你为我们带来了如此高品质的拼图体验！",
  ];

  static const _rareMessages = [
    "总会有地上的生灵，敢于直面雷霆的威光。",
    "荒地生星，灿如烈阳。天动万象，山海化形。",
    "愿你们今晚，得享美梦。",
    "代我看看这个世界，代我飞到高天之上。",
    "愿新的梦想永远不被侵蚀，旧的故事与苦难一同被忘却。愿绿色的原野、山丘永远不变得枯黄。愿溪水永远清澈，愿鲜花永远盛开。挚友将再次同行于茂密的森林中。一切美好的事物终将归来，一切痛苦的记忆也会远去，就像溪水净化自己，枯树绽出新芽。",
  ];
  static const _defaultMessagePostfix = "　";
  final BehaviorSubject<List<Gift>> _gifts = BehaviorSubject.seeded(Gift.all);
  final BehaviorSubject<int> _selected = BehaviorSubject.seeded(0);
  final BehaviorSubject<String> _message = BehaviorSubject.seeded("");
  bool _isRandom = true;

  ValueStream<List<Gift>> get gifts => _gifts.stream;

  ValueStream<int> get selected => _selected.stream;

  ValueStream<String> get message => _message.stream;

  String get _randomMessage {
    var random = Random();
    if (random.nextDouble() >= 0.95) {
      return _rareMessages[random.nextInt(_rareMessages.length)];
    } else {
      return _messages[random.nextInt(_messages.length)];
    }
  }

  GiftBloc() {
    useRandomMessage();
  }

  @override
  void dispose() {
    _gifts.close();
    super.dispose();
  }

  void updateMessage(String value) {
    _message.add(value);
  }

  void updateSelected(int value) {
    _selected.add(value);
  }

  void useRandomMessage() {
    updateMessage(_randomMessage);
    _isRandom = true;
  }

  Future<bool> confirmDonation() {
    return _callAlipay();
  }

  Future<bool> _callAlipay() {
    return launchUrlString(alipayUrl, mode: LaunchMode.externalApplication);
  }

  String get alipayUrl {
    var data = {
      "s": "money",
      "u": "2088302537808811",
      "a": _gifts.value[selected.value].price.toPrice(),
      "m": "${_message.value}${_isRandom ? _defaultMessagePostfix : ""}",
    };
    return "alipays://platformapi/startapp?appId=20000123&actionType=scan&biz_data=${json.encode(data)}";
  }
}
