import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_merger_dart/ui/widgets/images.dart';
import 'package:image_merger_dart/ui/widgets/popup.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:starrail_ui/views/dialog.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher_string.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  List<Tuple2<String, VoidCallback>> _getActions() => [
        Tuple2(
          "get image dimension (pure dart)",
          () async {
            var list = await pickImages(
              context: context,
              checkForPermission: true,
            );
            if (list.isEmpty) {
              return;
            }
            int start = DateTime.now().millisecondsSinceEpoch;
            img.Image image = img.decodeImage(list[0].readAsBytesSync())!;
            List<int> intList = [image.width, image.height];
            debugPrint("${DateTime.now().millisecondsSinceEpoch - start}ms");
            CardPopup.show(
              context,
              title: "Image Size",
              message: "${intList[0]}x${intList[1]}",
            );
          },
        ),
        Tuple2(
          "pay",
          () async {
            String url =
                'alipays://platformapi/startapp?appId=20000123&actionType=scan&biz_data={"s": "money","u": "2088302537808811","a": "0.01","m":"test"}';
            launchUrlString(url, mode: LaunchMode.externalApplication);
          },
        ),
        Tuple2(
          "webp",
          () async {
            SRDialog.showCustom(
              context: context,
              dialog: SRDialog.custom(
                  child: Image.asset(
                "assets/images/sushi.webp",
                width: 96,
                height: 96,
                fit: BoxFit.fill,
              )),
            );
          },
        ),
        Tuple2(
          "clipboard",
          () async {
            final imageBytes = await Pasteboard.image;
            if (imageBytes != null) {
              SRDialog.showCustom(
                  context: context,
                  dialog: SRDialog.custom(child: Center(child: Image.memory(imageBytes))));
            }
          },
        ),
      ];
  File? imageFile;

  @override
  Widget build(BuildContext context) {
    var actions = _getActions();
    return Scaffold(
      appBar: AppBar(title: const Text("Debug")),
      body: ListView.separated(
        itemBuilder: (BuildContext context, int index) {
          var action = actions[index];
          return ListTile(
            title: Text(action.item1),
            onTap: action.item2,
          );
        },
        itemCount: actions.length,
        separatorBuilder: (BuildContext context, int index) => Container(
          height: 1,
          color: Colors.black.withOpacity(0.1),
        ),
      ),
    );
  }
}
