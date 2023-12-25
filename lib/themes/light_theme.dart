import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.blue,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.red),
    titleTextStyle: TextStyle(color: Colors.black),
  )
);