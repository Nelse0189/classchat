import 'package:classchat/auth/register_classes.dart';
import 'package:classchat/button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:classchat/text_field.dart';
import '../main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

bool isClassRegistered = false;
final _firestore = FirebaseFirestore.instance;
final collectionRef = _firestore.collection('Users').doc(FirebaseAuth.instance.currentUser!.uid).get()
    .then((snapshot) => {
  isClassRegistered = snapshot.data()!['classRegistered'] as bool
});

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final emailTextController = TextEditingController();
  final passwordTextController = TextEditingController();

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
      if (context.mounted && isClassRegistered)
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => MyHomePage(title: 'ClassChat'),),);
      else
        (context.mounted && !isClassRegistered);
      Navigator.push(
        context, MaterialPageRoute(builder: (context) => RegisterClasses(),),);
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
      backgroundColor: Colors.grey[900],
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
                Text("Welcome back! You've been missed!"),
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
                    Text("Not a member?"),
                    const SizedBox(width: 4,),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        'Register Now!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
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
