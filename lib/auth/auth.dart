import 'package:classchat/auth/login_or_register.dart';
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
    _checkClassRegistration();
    getUserTheme();
  }

  void _checkClassRegistration() async {
    try {
      var snapshot = await _firestore.collection('Users').doc(FirebaseAuth.instance.currentUser!.email).get();
      setState(() {
        isClassRegistered = snapshot.data()?['classRegistered'] ?? false;
      });
    } catch (e) {
      // Handle any errors here
      print("Error fetching data: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context,snapshot){
          if (snapshot.hasData && isClassRegistered) {
            return const MyHomePage();
          }
          else if (snapshot.hasData && !isClassRegistered) {
            return RegisterClasses();
          }
          else{
            return const LoginOrRegister();
          }
      }
      )
    );
  }
}
