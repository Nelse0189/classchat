import 'package:classchat/auth/auth.dart';
import 'package:classchat/auth/register_classes.dart';
import 'package:classchat/button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:classchat/text_field.dart';
import '../main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:classchat/auth/constants.dart';

bool isClassRegistered = true;
final _firestore = FirebaseFirestore.instance;

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final emailTextController = TextEditingController();
  final passwordTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void checkIfClassRegistered() async {
    final user = FirebaseAuth.instance.currentUser!;
    final userData = await _firestore.collection('Users').doc(user.email).get();
    setState(() {
      isClassRegistered = userData['classRegistered'];
    });
  }

  //user sign in
  void signIn() async {
    //show progress
    showDialog(
        context: context,
        builder:(context) => const Center(
          child: CircularProgressIndicator(),
        ),
    );


    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailTextController.text,
        password: passwordTextController.text,
      );
      Navigator.push(
        context, MaterialPageRoute(builder: (context) => AuthPage(),),);
    } on FirebaseAuthException catch(e){
      Navigator.pop(context);
      displayMessage(e.code);
    }
  }
  //display dialog message
  void displayMessage(String message){
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
        title: Text(message),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock,
                  size: 100,
                  color: Colors.blue,
                ),
                Text("Welcome back! You've been missed!", style: TextStyle(fontFamily: 'sfPro', fontSize: 17),),
                const SizedBox(height: 25,),

                MyTextField(controller: emailTextController, hintText: 'Email', obscureText: false),

                const SizedBox(height: 10,),

                MyTextField(controller: passwordTextController, hintText: 'Password', obscureText: true),

                const SizedBox(height: 25,),
                //sign in butt
                MyButton(onTap: signIn, text: 'Sign in',),

                const SizedBox(height: 25,),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Not a member?", style: TextStyle(fontFamily: 'sfPro', fontSize: 14),),
                    const SizedBox(width: 4,),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        'Register Now!',
                        style: TextStyle(
                          fontFamily: 'sfProBold',
                          color: Colors.blue,
                        ),
                      ),
                    )
                  ],
                )





              ],

            ),
          ),
        ),
      ),
    );
  }
}
