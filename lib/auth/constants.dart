import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:classchat/settings.dart';

FirebaseFirestore _firestore = FirebaseFirestore.instance;
bool signOut = false;
User? currentUser = FirebaseAuth.instance.currentUser;
String realCurrentUsername = '';
String currentClass = '';
String selectedUser = '';
String dmID = '';
String currentUsername = FirebaseAuth.instance.currentUser!.email!;
String currentEmail = FirebaseAuth.instance.currentUser!.email!;
String colorMode= 'brightness: Brightness.light';
Color navBarColor = Colors.white70;
Color theme = Colors.blue.shade900;
Color theme2 = Colors.blue.shade50;
Color theme3 = Colors.red.shade300;
int refreshSignal = 0;
bool darkMode = false;
bool isBlue = false;
bool isRed = false;
bool isGreen = false;
bool isPink = false;
bool isPurple = false;
bool isYellow = false;
bool isOrange = false;
bool isBrown = false;
bool isGrey = false;
bool isBlack = false;
enum themeColor {blue, red, green, pink, purple, yellow, orange, brown, grey, black}

getUserTheme() async {
  DocumentSnapshot doc = await _firestore.collection('Users')
      .doc(currentEmail)
      .get();
  if (doc['theme'] == 'blue') {
    theme = Colors.blue.shade900;
    theme2 = Colors.blue.shade50;
    theme3 = Colors.red.shade900;
    navBarColor = Colors.white70;
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
    return themeColor.blue;
  } else if (doc['theme'] == 'red') {
    theme = Colors.red.shade500;
    theme2 = Colors.red.shade50;
    theme3 = Colors.blue.shade900;
    navBarColor = Colors.white70;
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
    return themeColor.red;
  } else if (doc['theme'] == 'green') {
    theme = Colors.green.shade500;
    theme2 = Colors.green.shade50;
    theme3 = Colors.red.shade500;
    navBarColor = Colors.white70;
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
    return themeColor.green;
  } else if (doc['theme'] == 'pink') {
    theme = Colors.pink.shade500;
    theme2 = Colors.pink.shade50;
    theme3 = Colors.blueAccent;
    navBarColor = Colors.white70;
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
    return themeColor.pink;
  } else if (doc['theme'] == 'purple') {
    theme = Colors.purple.shade500;
    theme2 = Colors.purple.shade50;
    theme3 = Colors.yellow.shade500;
    navBarColor = Colors.white70;
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
    return themeColor.purple;
  } else if (doc['theme'] == 'yellow') {
    theme = Colors.yellow.shade500;
    theme2 = Colors.yellow.shade50;
    theme3 = Colors.purple.shade500;
    navBarColor = Colors.white70;
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
    return themeColor.yellow;
  } else if (doc['theme'] == 'orange') {
    theme = Colors.orange.shade500;
    theme2 = Colors.orange.shade50;
    theme3 = Colors.blue.shade500;
    navBarColor = Colors.white70;
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
    return themeColor.orange;
  } else if (doc['theme'] == 'brown') {
    theme = Colors.brown.shade500;
    theme2 = Colors.brown.shade50;
    theme3 = Colors.teal;
    navBarColor = Colors.white70;
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
    return themeColor.brown;
  } else if (doc['theme'] == 'grey') {
    theme = Colors.grey.shade500;
    theme2 = Colors.grey.shade50;
    theme3 = Colors.redAccent;
    navBarColor = Colors.white70;
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
    return themeColor.grey;
  } else if (doc['theme'] == 'black') {
    theme = Colors.grey.shade700;
    theme2 = Colors.black87;
    theme3 = Colors.white12;
    navBarColor = Colors.black87;
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
    return themeColor.black;
  }
}

setUserTheme() async {
  if (isBlue) {
    await _firestore.collection('Users').doc(currentEmail).update({
      'theme': 'blue',
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
  }
  if (isRed) {
    await _firestore.collection('Users').doc(currentEmail).update({
      'theme': 'red',
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
  }
  if (isGreen) {
    await _firestore.collection('Users').doc(currentEmail).update({
      'theme': 'green',
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
  }
  if (isPink) {
    await _firestore.collection('Users').doc(currentEmail).update({
      'theme': 'pink',
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
  }
  if (isPurple) {
    await _firestore.collection('Users').doc(currentEmail).update({
      'theme': 'purple',
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
  }
  if (isYellow) {
    await _firestore.collection('Users').doc(currentEmail).update({
      'theme': 'yellow',
    });
    isOrange = false;
    isBlue = false;
    isRed = false;
    isGreen = false;
    isPink = false;
    isPurple = false;
    isYellow = true;
    isBrown = false;
    isGrey = false;
    isBlack = false;
  }
  if (isOrange) {
    await _firestore.collection('Users').doc(currentEmail).update({
      'theme': 'orange',
    });
    isBrown = false;
    isBlue = false;
    isRed = false;
    isGreen = false;
    isPink = false;
    isPurple = false;
    isYellow = false;
    isOrange = true;
    isGrey = false;
    isBlack = false;
  }
  if (isBrown) {
    await _firestore.collection('Users').doc(currentEmail).update({
      'theme': 'brown',
    });
    isGrey = false;
    isBlue = false;
    isRed = false;
    isGreen = false;
    isPink = false;
    isPurple = false;
    isYellow = false;
    isOrange = false;
    isBrown = true;
    isBlack = false;
  }
  if (isGrey) {
    await _firestore.collection('Users').doc(currentEmail).update({
      'theme': 'grey',
    });
    isGrey = true;
    isBlack = false;
    isBlue = false;
    isRed = false;
    isGreen = false;
    isPink = false;
    isPurple = false;
    isYellow = false;
    isOrange = false;
    isBrown = false;

  }
  if (isBlack) {
    await _firestore.collection('Users').doc(currentEmail).update({
      'theme': 'black',
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
  }
}

final userCollections = FirebaseFirestore.instance.collection('Users');
List<DocumentSnapshot> users = [];
List<DocumentSnapshot> permUsers = [];

void changeColorMode() {
  if (colorMode == 'dark') {
    colorMode = 'light';
  } else {
    colorMode = 'dark';
  }
}

Future<String> getUserId() async {
  QuerySnapshot querySnapshot = await userCollections.get();
  users = querySnapshot.docs;
  for (int i = 0; i < users.length; i++) {
    if (users[i].id == FirebaseAuth.instance.currentUser?.email) {
      currentUsername = users[i]['username'];
      users.add(users[i]['username']);
    }
  }
  return currentUsername;
}

nullifyCurrentClass() {
  currentClass = '';
}

generateDMID(currentUser) {
  if (currentUser!.compareTo(selectedUser) < 0) {
    dmID = currentUser! + selectedUser;
  } else {
    dmID = selectedUser + currentUser!;
  }
  print(dmID);
}

nullifyDMID() {
  dmID = '';
}

nullifySelectedUser() {
  selectedUser = '';
}


bool classesRegistered = false;