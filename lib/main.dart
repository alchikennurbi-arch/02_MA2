import 'package:edu_ws2026_ma204_pm/pages/home.dart';
import 'package:edu_ws2026_ma204_pm/service/Storage_service.dart';
import 'package:flutter/material.dart';
// import 'home_page.dart';
// import 'storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: HomePage()));
}
