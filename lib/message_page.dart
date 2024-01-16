import 'dart:ffi';

import 'package:classchat/auth/auth.dart';
import 'package:classchat/components/wall_post.dart';
import 'package:classchat/main.dart';
import 'package:classchat/text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth/constants.dart';
import 'class_page.dart';
import 'search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});



  @override
  State<HomePage> createState() => _HomePageState();
}



class _HomePageState extends State<HomePage> {


  @override
  void initState() {
    super.initState();
    generateDMID(FirebaseAuth.instance.currentUser!.email!);
  }

  final currentUser = FirebaseAuth.instance.currentUser!;
  final textController = TextEditingController();

  void signOut(){
    FirebaseAuth.instance.signOut();
    Navigator.push(context,MaterialPageRoute(builder: (context) => AuthPage(),),);
  }

  void postMessage(){
    if (textController.text.isNotEmpty){
      //store in firebase
      generateDMID(FirebaseAuth.instance.currentUser!.email!);
      FirebaseFirestore.instance.collection("User Posts" + currentClass + dmID).add({
        'currentUserName' : currentUser.displayName,
        'imgUrl' : currentUser.email,
        'UserEmail' : currentUser.email,
        "Message" : textController.text,
        'TimeStamp' : Timestamp.now(),
        'Likes' : [],
      });

    }
    setState(() {
      textController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text('ClassChat'),
        centerTitle: true,
        leading: BackButton(
          onPressed: () {
            nullifyDMID();
            nullifySelectedUser();
            nullifyCurrentClass();
            Navigator.push(context,MaterialPageRoute(builder: (context) => MyHomePage(title: 'ClassChat'),),);
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
                              currentUserName: post['currentUserName'],
                              userEmail: post['UserEmail'],
                              message: post['Message'],
                              imgUrl: post['imgUrl'],
                              postId: post.id,
                              likes: List<String>.from(post['Likes'] ?? []),
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
                padding: const EdgeInsets.all(25.0),
                child: Row(
                  children: [
                    Expanded(
                        child: MyTextField(
                          controller: textController,
                          hintText: "Write something on the wall...",
                          obscureText: false,
                        ),
                    ),
                    //Post Button
                    IconButton(onPressed: postMessage, icon: const Icon(Icons.arrow_circle_up)),
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
  