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

bool isClassRegistered = false;
final _firestore = FirebaseFirestore.instance;
final collectionRef = _firestore.collection('Users').doc(FirebaseAuth.instance.currentUser!.uid).get()
.then((snapshot) => {
  isClassRegistered = snapshot.data()!['classRegistered'] as bool
});
// Get a reference to a specific document if needed:
//final docRef = collectionRef.doc('classesRegistered');

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context,snapshot){
          if (snapshot.hasData && isClassRegistered == true) {
            return const MyHomePage(title: "ClassChat");
          }
          else if (snapshot.hasData && isClassRegistered == false) {
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
