import 'dart:typed_data';

import 'package:classchat/auth/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:classchat/text_field.dart';
import 'package:classchat/button.dart';
import 'package:classchat/auth/constants.dart';
import'package:classchat/resources/add_data.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';

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
  bool isLoading = false;
  late String imageUrl = '';
  Uint8List? _image;
  final _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> uploadImageToStorage(String childName,Uint8List file) async {
    Reference ref = _storage.ref().child(childName);
    UploadTask uploadTask = ref.putData(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<String> saveData({
    required Uint8List file,
  }) async {
    String resp = " Some Error Occurred";
    try{
      String imageUrl = await uploadImageToStorage(emailTextController.text, file);
      await _firestore.collection(emailTextController.text).add({
        'imageLink': imageUrl,
      });

      resp = 'success';
      print(resp);
    }
    catch(err){
      resp =err.toString();
    }
    print (resp);
    return resp;
  }


  Future<void> getImageUrl () async {
    setState(() {
      isLoading = true;
    });
    try {
      final ref = _storage.ref().child(emailTextController.text);
      final url = await ref.getDownloadURL();
      setState(() {
        imageUrl = url;
        isLoading = false; // End loading
      });
    } catch (e) {
      print("Error fetching image URL: $e");
      setState(() {
        isLoading = false; // End loading even if there's an error
      });
    }
    print(imageUrl) ;
  }

  Future<Uint8List> convertImageToUint8List(String assetPath) async {
    // Create a File instance from the given file path
    // Load the image as byte data from the asset bundle
    ByteData data = await rootBundle.load(assetPath);

    // Convert the byte data to Uint8List
    return data.buffer.asUint8List();
  }


  void saveProfile() async {
    print('saving profile');
    //save profile
    setState(() {
      isLoading = true;
    });
    Uint8List? _image = await convertImageToUint8List('images/owl2.png');
    String resp = await saveData(
        file: _image!
    );
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
  }

  void signUp() async {
    saveProfile();
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
