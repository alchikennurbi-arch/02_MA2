import 'package:flutter/material.dart';

Widget goodIcon(String n, [double s = 32]) => Image.asset(
  'assets/goods/$n.png',
  width: s,
  height: s,
  errorBuilder: (_, __, ___) => Icon(Icons.inventory_2, size: s),
);

Widget bgBox(Widget child) => Container(
  decoration: BoxDecoration(
    image: DecorationImage(
      image: AssetImage('assets/scenes/background.jpg'),
      fit: BoxFit.cover,
    ),
  ),
  child: child,
);
