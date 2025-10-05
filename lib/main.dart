import 'package:flutter/material.dart';
import 'package:ratix/screens/home_screen.dart';
import 'package:ratix/theme.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: primaryTheme,
    themeMode: ThemeMode.system,
    home: const Home(),
  ));
}
