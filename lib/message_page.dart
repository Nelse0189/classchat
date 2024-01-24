import 'dart:ffi';

import 'package:classchat/auth/auth.dart';
import 'package:classchat/components/wall_post.dart';
import 'package:classchat/main.dart';
import 'package:classchat/text_field.dart';
import 'package:classchat/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth/constants.dart';
import 'class_page.dart';
import 'search_page.dart';
import 'resources/add_data.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';
import 'class_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});



  @override
  State<HomePage> createState() => _HomePageState();
}



class _HomePageState extends State<HomePage> {
  Uint8List? _image;
  String _imageUrl = '';

  @override
  void initState() {
    super.initState();
    generateDMID(FirebaseAuth.instance.currentUser!.email!);
  }

  final currentUser = FirebaseAuth.instance.currentUser!;
  final textController = TextEditingController();

  String generateRandomString(int len) {
    var r = Random();
    const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
    return List.generate(len, (index) => _chars[r.nextInt(_chars.length)]).join();
  }

  void signOut(){
    FirebaseAuth.instance.signOut();
    Navigator.push(context,MaterialPageRoute(builder: (context) => AuthPage(),),);
  }

  void selectImage() async {
    final Uint8List? img = await pickImage(ImageSource.gallery);
    if (img != null) {
      setState(() {
        _image = img;
      });
    }
  }


  void postMessage() async {
    if (_image != null) {
      // Upload image and get URL
      _imageUrl = await StoreData().uploadImageToStorage(
        "user_posts/${FirebaseAuth.instance.currentUser!.email!}/${DateTime
            .now()
            .millisecondsSinceEpoch}",
        _image!,
      );
    }
      //store in firebase
      generateDMID(FirebaseAuth.instance.currentUser!.email!);
      FirebaseFirestore.instance.collection(
          "User Posts" + currentClass + dmID).add({
        'postImgUrl': _imageUrl,
        'currentUserName': currentUser.displayName,
        'imgUrl': currentUser.email,
        'UserEmail': currentUser.email,
        "Message": textController.text,
        'TimeStamp': Timestamp.now(),
        'Likes': [],
      });
      setState(() {
        textController.clear();
        _image = null;
        _imageUrl = '';
      });
    }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text('ClassChat', style: TextStyle(fontFamily: 'sfProBold'),),
        centerTitle: true,
        leading: BackButton(
          onPressed: () {
            nullifyDMID();
            nullifySelectedUser();
            nullifyCurrentClass();
            Navigator.push(context,MaterialPageRoute(builder: (context) => MyHomePage(),),);
          },
        ),
        actions: [
          IconButton(
              onPressed: signOut,
              icon: Icon(Icons.logout)),
        ],
      ),
          body: Column(
            children: [
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection("User Posts" + currentClass + dmID)
                    .orderBy(
                      "TimeStamp",
                      descending: false,
                     )
                    .snapshots(),
                    builder: (context, snapshot) {
                    if(snapshot.hasData){
                      //get the message
                      return Expanded(
                        child: ListView.builder(
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context,index) {
                            final post = snapshot.data!.docs[index];
                            return WallPost(
                              postImgUrl: post['postImgUrl'],
                              currentUserName: post['currentUserName'],
                              userEmail: post['UserEmail'],
                              message: post['Message'],
                              imgUrl: post['imgUrl'],
                              postId: post.id,
                              Likes: List<String>.from(post['Likes'] ?? []),
                            );
                          },
                        ),
                      );
                    } else if (snapshot.hasError){
                      return Center(
                        child: Text('Error:${snapshot.error}'),
                      );
                    }
                     return const Center(
                       child: CircularProgressIndicator(),
                    );
                  },
                ),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Row(
                  children: [
                    if (_image != null)
                      Image.memory(
                        _image!,
                        width: 100, // Adjust as needed
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    Expanded(
                        child: MyTextField(
                          controller: textController,
                          hintText: "Write something on the wall...",
                          obscureText: false,
                        ),
                    ),
                    //Post Button
                    IconButton(onPressed: postMessage, icon: const Icon(Icons.arrow_circle_up)),
                    IconButton(onPressed: selectImage, icon: const Icon(Icons.add_a_photo)),
                  ],
                ),
              ),
          
              Text("Logged in as: " + currentUser.email!),
              const SizedBox(height: 30),
            ],
          ),
    );
  }
}
  