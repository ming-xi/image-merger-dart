import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_merger_dart/ui/app.dart';
import 'package:image_merger_dart/ui/pages/debug.dart';
import 'package:image_merger_dart/ui/pages/gift.dart';
import 'package:image_merger_dart/ui/pages/merge_image.dart';
import 'package:starrail_ui/views/blur.dart';
import 'package:starrail_ui/views/card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ThemedState<HomePage> {
  Widget _buildCard({
    required String text,
    required VoidCallback onTap,
  }) {
    return SRCard(
      child: Ink(
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(text, textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("拼图"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/images/back.jpg", fit: BoxFit.cover),
          ),
          Blurred(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: kToolbarHeight + 16),
                  Expanded(
                    child: _buildCard(
                      text: "开始拼图",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MergeImagePage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildCard(
                      text: "赞赏作者",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GiftPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (kDebugMode)
                    Expanded(
                      child: _buildCard(
                        text: "Debug",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DebugPage(),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
