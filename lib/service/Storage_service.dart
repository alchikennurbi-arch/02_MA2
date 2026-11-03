import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static late SharedPreferences p;
  static Future init() async => p = await SharedPreferences.getInstance();

  // settings
  static String get difficulty => p.getString('diff') ?? 'Easy';
  static set difficulty(String v) => p.setString('diff', v);

  static double get music => p.getDouble('music') ?? 0.5;
  static set music(double v) => p.setDouble('music', v);
  
  static double get sfx => p.getDouble('sfx') ?? 0.5;
  static set sfx(double v) => p.setDouble('sfx', v);

  // unfinished game
  static Map? get game {
    var s = p.getString('game');
    return s == null ? null : jsonDecode(s);
  }

  static void saveGame(Map? g) =>
      g == null ? p.remove('game') : p.setString('game', jsonEncode(g));

  // records (newest first)
  static List get records => jsonDecode(p.getString('records') ?? '[]');
  static void addRecord(Map r) {
    var l = records;
    l.insert(0, r);
    p.setString('records', jsonEncode(l));
  }
}
