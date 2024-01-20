import 'package:classchat/auth/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:classchat/text_field.dart';
import 'package:classchat/button.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  @override
  final emailTextController = TextEditingController();
  final passwordTextController = TextEditingController();
  final confirmPasswordTextController = TextEditingController();

  void signUp() async {
    showDialog(
      context: context,
      builder:(context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    //make sure passwords match
    if (passwordTextController.text != confirmPasswordTextController.text){
      Navigator.push(context, MaterialPageRoute(builder: (context) => AuthPage(),),);;
      //show error to user
      displayMessage("Passwords don't match");
      return;
    }

    try{
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: emailTextController.text, password: passwordTextController.text,);
      //creating new document in firestore called Users

      FirebaseFirestore.instance.collection('Users')
      .doc(userCredential.user!.email)
      .set({
        'Friends' : [],
        'username' : emailTextController.text.split('@')[0],
        'bio' : 'Empty bio...',
        'classesRegistered' : false,
        'theme' : 'default',
      });
      CollectionReference classesCollection = FirebaseFirestore.instance
          .collection('Users')
          .doc(userCredential.user!.email)
          .collection('classes');
      FirebaseAuth.instance.currentUser!.updateDisplayName(emailTextController.text.split('@')[0]);

      if(context.mounted) Navigator.push(context, MaterialPageRoute(builder: (context) => AuthPage(),),);;
    } on FirebaseAuthException catch (e) {
      //pop loading circle
      Navigator.pop(context);
      //show error to user
      displayMessage(e.code);
    }
  }
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock,
                    size: 100,
                    color: Colors.black87,
                  ),
                  Text("Let's create an Account for you!"),
                  const SizedBox(height: 25,),

                  MyTextField(controller: emailTextController, hintText: 'Email', obscureText: false,),

                  const SizedBox(height: 10,),

                  MyTextField(controller: passwordTextController, hintText: 'Password', obscureText: true),

                  const SizedBox(height: 10,),

                  MyTextField(controller: confirmPasswordTextController, hintText: 'Confirm Password', obscureText: true),

                  const SizedBox(height: 25,),
                  //sign in button
                  MyButton(onTap: signUp, text: 'Sign up',),

                  const SizedBox(height: 25,),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account?", style: TextStyle(fontFamily: 'sfPro', fontSize: 15),),
                      const SizedBox(width: 4,),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: const Text(
                          'Log in!',
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
      ),
    );
  }
}
