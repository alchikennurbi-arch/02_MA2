import 'package:edu_ws2026_ma204_pm/pages/Game.dart';
import 'package:edu_ws2026_ma204_pm/pages/Records.dart';
import 'package:edu_ws2026_ma204_pm/pages/Settings.dart';
import 'package:edu_ws2026_ma204_pm/service/Storage_service.dart';
import 'package:flutter/material.dart';
import '../common.dart';
// import 'storage.dart';
// import 'game_page.dart';
// import 'records_page.dart';
// import 'settings_page.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomeState();
}

class _HomeState extends State<HomePage> {
  go(Widget w) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    setState(() {}); // Continue батырмасын жаңарту
  }

  Widget btn(String t, VoidCallback f) => Padding(
    padding: EdgeInsets.all(6),
    child: SizedBox(
      width: 240,
      height: 50,
      child: ElevatedButton(onPressed: f, child: Text(t)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: bgBox(
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/scenes/logo.png', height: 150),
              if (Storage.game != null)
                btn('Continue', () => go(GamePage(newGame: false))),
              btn('Start Game', () => go(GamePage(newGame: true))),
              btn('Records', () => go(RecordsPage())),
              btn('Settings', () => go(SettingsPage())),
            ],
          ),
        ),
      ),
    );
  }
}
