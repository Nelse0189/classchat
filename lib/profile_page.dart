import 'dart:typed_data';
import 'auth/register_classes.dart';
import 'resources/add_data.dart';
import 'package:classchat/text_box.dart';
import 'package:classchat/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'settings.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  //user
  bool isLoading = true;
  final currentUser = FirebaseAuth.instance.currentUser!;
  final userCollections = FirebaseFirestore.instance.collection('Users');
  Uint8List? _image;
  late String imageUrl = '';
  final storage = FirebaseStorage.instance;

  void initState() {
    super.initState();
    getImageUrl();
    currentUser.reload();
  }

  Future<void> getImageUrl () async {
    setState(() {
      isLoading = true;
    });
    try {
      final ref = storage.ref().child(currentUser.email!);
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

  void saveProfile() async {
    //save profile
    setState(() {
      isLoading = true;
    });

    String resp = await StoreData().saveData(
        file: _image!
    );
    setState(() {
      isLoading = false;
    });
  }

  Future<void> editField(String field) async {
    String newValue = "";
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            "Edit "+ field,
            style: const TextStyle(color: Colors.amber),
          ),
          content: TextField(
          autofocus: true,
          style: TextStyle(color: Colors.amber),
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
                child: Text('Cancel', style: TextStyle(color: Colors.amber),),),
            //save button
            TextButton(
                onPressed: () => Navigator.of(context).pop(newValue),
                child: Text('Save', style: TextStyle(color: Colors.amber),),),
          ],
        ),
    );
    //update in firestore
    if (newValue.trim().length>0) {
      //only update if there is a new value
      await userCollections.doc(currentUser.email).update({field: newValue});
    }
    FirebaseAuth.instance.currentUser!.updateDisplayName(newValue);
  }
  void selectImage () async {
    setState(() {
      isLoading = true;
    });
    Uint8List img = await pickImage(ImageSource.gallery);
    if(img != null){
      setState(() {
        _image = img;
      });
      saveProfile();
    }
    setState(() {
      isLoading = false;
    });
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
                const SizedBox(height: 50,),
                Stack(
                  alignment: Alignment.center,
                  children: [
                const SizedBox(height: 50,),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    isLoading ?
                      const CircularProgressIndicator() :
                    CircleAvatar(
                      key : UniqueKey(),
                      radius: 64,
                      backgroundImage: imageUrl.isNotEmpty
                        ? NetworkImage(imageUrl + '?v=${UniqueKey().toString()}')
                        : NetworkImage('https://upload.wikimedia.org/wikipedia/commons/9/99/Sample_User_Icon.png'),
                  ),
                  ],
                ),
                  Positioned(
                    child: IconButton
                    (onPressed: selectImage,
                    icon: Icon(Icons.add_a_photo, color: Colors.blueGrey, size: 30,),
                  ),
                  bottom: -10,
                  right: 130
                    ,
                  ),
          ],
                ),
                const SizedBox(height: 20,),

                Text(
                  currentUser.email!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.lightBlueAccent, fontFamily: 'Roboto', fontWeight: FontWeight.bold, fontSize: 16),
                ),

                const SizedBox(height: 50,),

                Padding(
                  padding: const EdgeInsets.only(left:25),
                  child: Text(
                    'My Details',
                    style: TextStyle(color: Colors.lightBlueAccent, fontFamily: 'Roboto', fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                //username
                MyTextBox(
                  text: userData ['username'],
                  sectionName: "username",
                  onPressed: () => editField('username'),
                ),
                MyTextBox(
                  text: userData ['bio'],
                  sectionName: "bio",
                  onPressed: () => editField('bio'),
                ),
                const SizedBox(height: 50,),

                Container(
                  height: 50,
                  width: 150,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterClasses(),),),
                    child: Text('Change Registered Classes'),
                  ),
                ),
                const SizedBox(height: 20,),


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
