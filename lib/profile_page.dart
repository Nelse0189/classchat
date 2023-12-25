import 'package:classchat/text_box.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  //user
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
      await userCollections.doc(currentUser.email).update({field: newValue});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('Users').doc(currentUser.email).snapshots(),
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
                  currentUser.email!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.redAccent),
                ),

                const SizedBox(height: 50,),

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
                  onPressed: () => editField('username') ,
                ),
                MyTextBox(
                  text: userData ['bio'],
                  sectionName: "bio",
                  onPressed: () => editField('bio'),
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
