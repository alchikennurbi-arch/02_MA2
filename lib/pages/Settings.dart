import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:edu_ws2026_ma204_pm/common.dart';
import 'package:edu_ws2026_ma204_pm/service/Storage_service.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<SettingsPage> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsPage> {
  String diff = Storage.difficulty;
  double music = Storage.music, sfx = Storage.sfx;
  final player = AudioPlayer();
  Timer? timer;

  void start(String file, double v) {
    timer?.cancel();
    player.setReleaseMode(ReleaseMode.loop);
    player.play(AssetSource('audios/$file.mp3'), volume: v);
  }

  void stop() {
    timer?.cancel();
    timer = Timer(Duration(seconds: 1), () => player.stop());
  }

  @override
  void dispose() {
    timer?.cancel();
    
    player.dispose();
    super.dispose();
  }

  Widget slider(String title, double v, String file, Function(double) save) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        Slider(
          value: v,
          onChangeStart: (x) => start(file, x),
          onChanged: (x) {
            save(x);
            player.setVolume(x);
          },
          onChangeEnd: (_) => stop(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: bgBox(
        Center(
          child: Card(
            child: SizedBox(
              width: 400,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Game Difficulty'),
                    Row(
                      children: [
                        for (var d in ['Easy', 'Hard'])
                          Padding(
                            padding: EdgeInsets.all(4),
                            child: ChoiceChip(
                              label: Text(d),
                              selected: diff == d,
                              onSelected: (_) {
                                setState(() => diff = d);
                                Storage.difficulty = d;
                              },
                            ),
                          ),
                      ],
                    ),
                    slider('Background Music', music, 'background', (x) {
                      setState(() => music = x);
                      Storage.music = x;
                    }),
                    slider('Game Sound Effects', sfx, 'buy', (x) {
                      setState(() => sfx = x);
                      Storage.sfx = x;
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
