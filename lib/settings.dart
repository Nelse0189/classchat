import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:classchat/auth/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
class ThemePage extends StatefulWidget {
  const ThemePage({super.key});


  @override
  State<ThemePage> createState() => _ThemePageState();
}


class _ThemePageState extends State<ThemePage> {
  themeColor _themeChoice = themeColor.blue;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Theme', style: TextStyle(fontFamily: 'sfPro'),),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Blue', style: TextStyle(color: Colors.blue, fontFamily: 'sfPro')),
            trailing: Switch(
              value: _themeChoice == themeColor.blue,
              onChanged: (value) async {
                theme = Colors.blue.shade300;
                setState(() {
                  _themeChoice = themeColor.blue;
                });
                isBlue = true;
                isRed = false;
                isGreen = false;
                isPink = false;
                isPurple = false;
                isYellow = false;
                isOrange = false;
                isBrown = false;
                isGrey = false;
                isBlack = false;
                await setUserTheme();
                print(_themeChoice == themeColor.blue);
              },
            ),
          ),
          ListTile(
            title: Text('Red', style: TextStyle(color: Colors.red, fontFamily: 'sfPro')),
            trailing: Switch(
              value: _themeChoice == themeColor.red,
              onChanged: (value) async {
                theme = Colors.red.shade300;
                setState(() {
                  _themeChoice = themeColor.red;
                });
                isRed = true;
                isBlue = false;
                isGreen = false;
                isPink = false;
                isPurple = false;
                isYellow = false;
                isOrange = false;
                isBrown = false;
                isGrey = false;
                isBlack = false;
                await setUserTheme();
                print(_themeChoice == themeColor.red);
              },
            ),
          ),
          ListTile(
            title: Text('Green', style: TextStyle(color: Colors.green, fontFamily: 'sfPro')),
            trailing: Switch(
              value: _themeChoice == themeColor.green,
              onChanged: (value) async {
                theme = Colors.green.shade300;
                setState(() {
                  _themeChoice = themeColor.green;
                });
                isGreen = true;
                isBlue = false;
                isRed = false;
                isPink = false;
                isPurple = false;
                isYellow = false;
                isOrange = false;
                isBrown = false;
                isGrey = false;
                isBlack = false;
                await setUserTheme();
                print(_themeChoice == themeColor.green);
              },
            ),
          ),
          ListTile(
            title: Text('Purple', style: TextStyle(color: Colors.purple, fontFamily: 'sfPro')),
            trailing: Switch(
              value: _themeChoice == themeColor.purple,
              onChanged: (value) async {
                theme = Colors.purple.shade300;
                setState(() {
                  _themeChoice = themeColor.purple;
                });
                isPurple = true;
                isBlue = false;
                isRed = false;
                isGreen = false;
                isPink = false;
                isYellow = false;
                isOrange = false;
                isBrown = false;
                isGrey = false;
                isBlack = false;
                await setUserTheme();
                print(_themeChoice == themeColor.purple);
              },
            ),
          ),
          ListTile(
            title: Text('Pink', style: TextStyle(color: Colors.pink, fontFamily: 'sfPro')),
            trailing: Switch(
              value: _themeChoice == themeColor.pink,
              onChanged: (value) async {
                theme = Colors.pink.shade300;
                setState(() {
                  _themeChoice = themeColor.pink;
                });
                isPink = true;
                isBlue = false;
                isRed = false;
                isGreen = false;
                isPurple = false;
                isYellow = false;
                isOrange = false;
                isBrown = false;
                isGrey = false;
                isBlack = false;
                await setUserTheme();
                print(_themeChoice == themeColor.pink);
              },
            ),
          ),
          ListTile(
            title: Text('Yellow', style: TextStyle(color: Colors.yellow, fontFamily: 'sfPro')),
            trailing: Switch(
              value: _themeChoice == themeColor.yellow,
              onChanged: (value) async {
                theme = Colors.yellow.shade300;
                setState(() {
                  _themeChoice = themeColor.yellow;
                });
                isYellow = true;
                isBlue = false;
                isRed = false;
                isGreen = false;
                isPink = false;
                isPurple = false;
                isOrange = false;
                isBrown = false;
                isGrey = false;
                isBlack = false;
                await setUserTheme();
                print(_themeChoice == themeColor.yellow);
              },
            ),
          ),
          ListTile(
            title: Text('Orange', style: TextStyle(color: Colors.orange, fontFamily: 'sfPro')),
            trailing: Switch(
              value: _themeChoice == themeColor.orange,
              onChanged: (value) async {
                theme = Colors.orange.shade300;
                setState(() {
                  _themeChoice = themeColor.orange;
                });
                isOrange = true;
                isBlue = false;
                isRed = false;
                isGreen = false;
                isPink = false;
                isPurple = false;
                isYellow = false;
                isBrown = false;
                isGrey = false;
                isBlack = false;
                await setUserTheme();
                print(_themeChoice == themeColor.orange);
              },
            ),
          ),
          ListTile(
            title: Text('Brown', style: TextStyle(color: Colors.brown, fontFamily: 'sfPro')),
            trailing: Switch(
              value: _themeChoice == themeColor.brown,
              onChanged: (value) async {
                theme = Colors.brown.shade300;
                setState(() {
                  _themeChoice = themeColor.brown;
                });
                isBrown = true;
                isBlue = false;
                isRed = false;
                isGreen = false;
                isPink = false;
                isPurple = false;
                isYellow = false;
                isOrange = false;
                isGrey = false;
                isBlack = false;
                await setUserTheme();
                print(_themeChoice == themeColor.brown);
              },
            ),
          ),
          ListTile(
            title: Text('Grey', style: TextStyle(color: Colors.grey, fontFamily: 'sfPro')),
            trailing: Switch(
              value: _themeChoice == themeColor.grey,
              onChanged: (value) async {
                theme = Colors.grey.shade300;
                setState(() {
                  _themeChoice = themeColor.grey;
                });
                isGrey = true;
                isBlue = false;
                isRed = false;
                isGreen = false;
                isPink = false;
                isPurple = false;
                isYellow = false;
                isOrange = false;
                isBrown = false;
                isBlack = false;
                await setUserTheme();
                print(_themeChoice == themeColor.grey);
              },
            ),
          ),
          ListTile(
            title: Text('Black', style: TextStyle(color: Colors.black, fontFamily: 'sfPro')),
            trailing: Switch(
              value: _themeChoice == themeColor.black,
              onChanged: (value) async {
                theme = Colors.black;
                setState(() {
                  _themeChoice = themeColor.black;
                });
                isBlack = true;
                isBlue = false;
                isRed = false;
                isGreen = false;
                isPink = false;
                isPurple = false;
                isYellow = false;
                isOrange = false;
                isBrown = false;
                isGrey = false;
                await setUserTheme();
                print(_themeChoice == themeColor.black);
              },
            ),
          ),
        ],
      ),
    );
  }
}


