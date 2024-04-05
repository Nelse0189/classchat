import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:classchat/auth/constants.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'auth/register_classes.dart';
import 'auth/constants.dart';
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
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'bought_items.dart';
import 'sold_items.dart';
import 'user_selling_items_page.dart'; // Adjust the import path as necessary
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shimmer/shimmer.dart';

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

  void shareApp() {
    Share.share('Check out this amazing app: https//:www.example.com',
        subject: 'An Invitation to Skubble');
  }


  Future<void> getImageUrl() async {
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
    print(imageUrl);
  }

  void saveProfile() async {
    setState(() {
      isLoading = true;
    });
    String resp;
    if (_image != null) {
      resp = await StoreData().saveData(file: _image!);
      if (resp == 'success') {
        await getImageUrl(); // Fetch and update the imageUrl state.
      }
    } else {
      // Handle the case where _image is null
      resp = 'No image selected';
    }

    // Update UI after operation
    setState(() {
      isLoading = false;
    });

    // Optionally, show a toast or dialog with the result
  }


  Future<void> _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'skubble@gmail.com',
      query: encodeQueryParameters(<String, String>{
        'subject': 'Your Subject Here',
      }),
    );

    if (await canLaunch(emailUri.toString())) {
      await launch(emailUri.toString());
    } else {
      throw 'Could not launch ${emailUri.toString()}';
    }
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }


  Future<void> addUsernameLowercaseField() async {
    final userCollection = FirebaseFirestore.instance.collection('Users');

    // Fetch all user documents
    final snapshot = await userCollection.get();

    // Iterate over all user documents
    for (var doc in snapshot.docs) {
      final userDoc = doc.data();
      if (userDoc != null) {
        final username = userDoc['username'];
        // Check if the username_lowercase field does not exist or needs updating
        if (username != null && (userDoc['username_lowercase'] == null || userDoc['username_lowercase'] != username.toLowerCase())) {
          // Update the document with the new username_lowercase field
          await userCollection.doc(doc.id).update({
            'username_lowercase': username.toLowerCase(),
          });
        }
      }
    }
  }

  void contactSupport() {
    // Define what happens when you press the Contact Support button
    // For example, show a dialog or navigate to a support page
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Contact Support"),
          content: Text("For support, please email us at skubblehelp@gmail.com"),
          actions: [
            TextButton(
              child: Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }




  Future<void> editField(String field) async {
    String newValue = "";
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme,
        title: Text(
          "Edit "+ field,
          style: TextStyle(color: Colors.white, fontFamily: 'sfProBold'),
        ),
        content: TextField(
          autofocus: true,
          style: TextStyle(color: Colors.white, fontFamily: 'sfPro'),
          decoration: InputDecoration(
            hintText: "Enter New" + field,
            hintStyle: TextStyle(color: Colors.white, fontFamily: 'sfPro'),
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
    if(field == 'username') {
      await userCollections.doc(currentUser.email).update({'username_lowercase': newValue.toLowerCase()});
    }
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
        appBar: AppBar(
          automaticallyImplyLeading: false,
          iconTheme: IconThemeData(color: Colors.white),
          backgroundColor: theme,
          titleTextStyle: TextStyle(fontFamily: 'sfPro', color: Colors.white, fontSize: 20),
          title: Shimmer.fromColors(
            baseColor: Colors.white,
            highlightColor: theme2,
            child: Text(
              'Skubble',
              style: TextStyle(
                fontFamily: 'SfProBold',
              ),
            ),
          ),
          centerTitle: true,
        ),

        body: Stack(
          children: [
            Positioned.fill(
              child: Shimmer.fromColors(
                baseColor: theme2,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  color: theme2,
                ),
              ),
            ),
            Container(
            child: StreamBuilder<DocumentSnapshot>(
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
                          CachedNetworkImage(
                            imageUrl: imageUrl, // Use the imageUrl that you fetched
                            placeholder: (context, url) => CircularProgressIndicator(), // Show loader while the image loads
                            errorWidget: (context, url, error) =>  CircularProgressIndicator(),
                            // Show an error icon if the image fails to load
                            imageBuilder: (context, imageProvider) => CircleAvatar(
                              backgroundColor: Colors.lightBlueAccent,
                              radius: 100, // Set the radius accordingly
                              backgroundImage: imageProvider, // Use the imageProvider from CachedNetworkImage
                            ),
                          ),
                          /*isLoading ?
                          const CircularProgressIndicator() :
                          CircleAvatar(
                            key : UniqueKey(),
                            radius: 100,
                            backgroundImage: imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl + '?v=${UniqueKey().toString()}')
                              : NetworkImage('https://upload.wikimedia.org/wikipedia/commons/9/99/Sample_User_Icon.png'),
                          */
                          Positioned(
                            child: IconButton
                              (onPressed: selectImage,
                              icon: Icon(Icons.add_a_photo, color: theme, size: 25,),
                            ),
                            bottom: -10,
                            right: 130
                            ,
                          ),
                        ],

                        //const SizedBox(height: 1,),

                        //Text(
                        //currentUser.email!,
                        //textAlign: TextAlign.center,
                        //style: TextStyle(color: Colors.black, fontFamily: 'sfProSemiBold', fontSize: 16),
                        //),
                      ),

                      const SizedBox(height: 30,),

                      Padding(
                        padding: const EdgeInsets.only(left:25),
                        child: Text(
                          'My Details',
                          style: TextStyle(color: Colors.black, fontFamily: 'sfProSemiBold', fontSize: 14),
                        ),
                      ),
                      //username
                      MyTextBox(
                        text: userData ['username'],
                        sectionName: "Username",
                        onPressed: () => editField('username'),
                      ),
                      MyTextBox(
                        text: userData ['bio'],
                        sectionName: "Bio",
                        onPressed: () => editField('bio'),
                      ),
                      const SizedBox(height: 15,),


                      const SizedBox(height: 10,),
                      Container(
                        height: 50,
                        width: 150,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme,
                          ),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ThemePage(),),),
                          child: Text('Settings', style: TextStyle(color: Colors.white, fontFamily: 'sfProSemiBold', fontSize: 14),),
                        ),
                      ),
                      const SizedBox(height: 10,),
                      Container(
                        height: 50,
                        width: 150,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme,
                          ),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BoughtItemsPage(),),),
                          child: Text('Bought Items', style: TextStyle(color: Colors.white, fontFamily: 'sfProSemiBold', fontSize: 14),),
                        ),
                      ),
                      const SizedBox(height: 10,),
                      Container(
                        height: 50,
                        width: 150,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme,
                          ),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SellerItemsPage(),),),
                          child: Text('Sold Items', style: TextStyle(color: Colors.white, fontFamily: 'sfProSemiBold', fontSize: 14),),
                        ),
                      ),
                      const SizedBox(height: 10,),
                      Container(
                        height: 50,
                        width: 150,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserItemsPage(userEmail: currentEmail),
                              ),
                            );
                          },
                          child: Text('My Items',style: TextStyle(color: Colors.white, fontFamily: 'sfProSemiBold', fontSize: 14),),
                        ),
                      ),
                      const SizedBox(height: 10,),
                      IconButton(
                        onPressed: contactSupport,
                        icon: Icon(Icons.support_agent),
                        color: theme3,
                      ),
                      IconButton(
                        onPressed: shareApp, // Call the shareApp method when the button is tapped
                        icon: Icon(Icons.share),
                        color: theme3,
                      ),
                      SizedBox(height: 10,),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Buyer Rating:',
                                style: TextStyle(fontFamily: 'sfPro', fontSize: 14, color: theme3)),
                            RatingBarIndicator(
                              rating: userData['buyerRating']?.toDouble() ?? 0.0,
                              itemBuilder: (context, index) => Icon(Icons.star, color: theme),
                              itemCount: 5,
                              itemSize: 30.0,
                              direction: Axis.horizontal,
                            ),
                            Text('${userData['buyerRating']?.toStringAsFixed(1) ?? ''} (${userData['buyerRatingAmount'] ?? 0})',
                                style: TextStyle(fontFamily: 'sfPro', fontSize: 16, color: theme3)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Seller Rating:',
                                style: TextStyle(fontFamily: 'sfPro', fontSize: 14, color: theme3)),
                            RatingBarIndicator(
                              rating: userData['sellerRating']?.toDouble() ?? 0.0,
                              itemBuilder: (context, index) => Icon(Icons.star, color: theme),
                              itemCount: 5,
                              itemSize: 30.0,
                              direction: Axis.horizontal,
                            ),
                            Text('${userData['sellerRating']?.toStringAsFixed(1) ?? ''} (${userData['sellerRatingAmount'] ?? 0})',
                                style: TextStyle(fontFamily: 'sfPro', fontSize: 16, color: theme3)),
                          ],
                        ),
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error'+ snapshot.error.toString()),
                  );
                }
                return const Center(child: CircularProgressIndicator(),);
              },),
          ),
      ],
        )
    );
  }
}
