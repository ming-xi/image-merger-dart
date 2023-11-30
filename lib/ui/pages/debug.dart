import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:starrail_ui/views/dialog.dart';
import 'package:tuple/tuple.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  List<Tuple2<String, VoidCallback>> _getActions() => [
        Tuple2(
          "clipboard",
          () async {
            final imageBytes = await Pasteboard.image;
            if (imageBytes != null) {
              SRDialog.showCustom(
                context: context,
                dialog: SRDialog.custom(
                  child: Center(child: Image.memory(imageBytes)),
                ),
              );
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
