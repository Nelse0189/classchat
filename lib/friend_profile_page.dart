import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:classchat/text_box.dart';
import 'auth/constants.dart';

class FriendProfilePage extends StatefulWidget {
  const FriendProfilePage({super.key});

  @override
  State<FriendProfilePage> createState() => _FriendProfilePageState();
}

class _FriendProfilePageState extends State<FriendProfilePage> {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final userCollections = FirebaseFirestore.instance.collection('Users');

    Future<void> editField(String field) async {
      String newValue = "";
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            "Edit "+ field,
            style: const TextStyle(color: Colors.white),
          ),
          content: TextField(
            autofocus: true,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter New" + field,
              hintStyle: TextStyle(color: Colors.grey),
            ),
            onChanged: (value) {
              newValue = value;

            },
          ),
          actions: [
            //cancel button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.white),),),
            //save button
            TextButton(
              onPressed: () => Navigator.of(context).pop(newValue),
              child: Text('Save', style: TextStyle(color: Colors.white),),),
          ],
        ),
      );
      //update in firestore
      if (newValue.trim().length>0) {
        //only update if there is a new value
        await userCollections.doc(selectedUser).update({field: newValue});
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Center(child: Text('ClassChat')),
        ),
          body: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('Users').doc(selectedUser).snapshots(),
            builder: (context, snapshot){
              if (snapshot.hasData) {
                //get user data
                final userData = snapshot.data!.data() as Map<String, dynamic>;
                return ListView(
                  children: [
                    const SizedBox(height: 50),
                    Icon(
                      Icons.person,
                      size: 72,
                    ),

                    Text(
                      selectedUser!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.redAccent),
                    ),

                    const SizedBox(height: 10,),

                    Center(
                      child: InkWell(
                        onTap: () => {
                          //add friend
                          userCollections.doc(currentUser.email).update({'Friends': FieldValue.arrayUnion([selectedUser])})
                        },
                        child: Text(
                          'Add Friend',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20,),

                    Padding(
                      padding: const EdgeInsets.only(left:25),
                      child: Text(
                        'My Details',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                    //username
                    MyTextBox(
                      text: userData ['username'],
                      sectionName: "username",
                      onPressed: () => {},
                    ),
                    MyTextBox(
                      text: userData ['bio'],
                      sectionName: "bio",
                      onPressed: () => {},
                    ),
                  ],
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Error'+ snapshot.error.toString()),
                );
              }
              return const Center(child: CircularProgressIndicator(),);
            },)
      );
    }
  }

