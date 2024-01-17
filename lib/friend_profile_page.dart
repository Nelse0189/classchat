import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:classchat/text_box.dart';
import 'auth/constants.dart';
import 'message_page.dart';


class FriendProfilePage extends StatefulWidget {
  const FriendProfilePage({super.key});

  @override
  State<FriendProfilePage> createState() => _FriendProfilePageState();
}

class _FriendProfilePageState extends State<FriendProfilePage> {
  final storage = FirebaseStorage.instance;
  late String imageUrl = '';
    final currentUser = FirebaseAuth.instance.currentUser!;
    final userCollections = FirebaseFirestore.instance.collection('Users');

    void initState() {
      super.initState();
      getImageUrl();
    }

  Future<void> getImageUrl () async {
    final ref = storage.ref().child(selectedUser);
    final url = await ref.getDownloadURL();
    setState(() {
      imageUrl = url;
    });
  }

  Future<String> getUsernameFromEmail(String userEmail) async {
    try {
      DocumentSnapshot userDoc = await userCollections.doc(userEmail).get();
      if (userDoc.exists) {
        return userDoc['username'] as String; // Assuming 'username' field exists
      } else {
        throw Exception("User not found");
      }
    } catch (e) {
      print(e);
      throw Exception("Error retrieving username");
    }
  }

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
                    CircleAvatar(
                      radius: 64,
                      backgroundImage: NetworkImage(
                        imageUrl != '' ? imageUrl : 'https://www.pngitem.com/pimgs/m/30-307416_profile-icon-png-image-free-download-searchpng-employee.png',
                      ),
                    ),
                    const SizedBox(height: 20,),

                    Text(
                      selectedUser!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.amber),
                    ),

                    const SizedBox(height: 10,),

                    Center(
                      child: InkWell(
              onTap: () async {
              try {
              String friendUsername = await getUsernameFromEmail(selectedUser);
              userCollections.doc(currentUser.email).update({
              'Friends': FieldValue.arrayUnion([friendUsername])
              });
              Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
              );
              } catch (e) {
              print("Error adding friend: $e");
              }
              },
              // Rest of your InkWell properties...

                        child: Text(
                          'Direct Message',
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

