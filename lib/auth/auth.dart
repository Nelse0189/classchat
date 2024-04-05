import 'package:classchat/auth/login_or_register.dart';
import 'package:classchat/auth/login_page.dart';
import 'package:classchat/auth/register_classes.dart';
import 'package:classchat/profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:classchat/message_page.dart';
import 'package:classchat/main.dart';
import 'constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class AuthPage extends StatefulWidget {
  AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isClassRegistered = false;

  @override
  void initState() {
    super.initState();
    //_checkClassRegistration();
    getUserTheme();
  }

   /*Future<bool> _checkClassRegistration() async {
     var snapshot = await _firestore.collection('Users').doc(
         FirebaseAuth.instance.currentUser!.email).get();
     isClassRegistered = snapshot.data()?['classRegistered'];
     return isClassRegistered;
   }*/





  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, authSnapshot) {
                if(authSnapshot.connectionState == ConnectionState.waiting){
                  return Container(
                      color: Colors.white70,
                      child: Center(child: CircularProgressIndicator()));
                } else if (authSnapshot.hasData) {
                  return MyHomePage();
                }
                 else {
                  print(authSnapshot);
                  return LoginPage();
                }
              });
  }
}
