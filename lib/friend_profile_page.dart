import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:classchat/text_box.dart';
import 'auth/constants.dart';
import 'message_page.dart';
import 'text_box2.dart';
import 'auth/constants.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

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
  bool isLoading = true;

  void initState() {
    super.initState();
    getImageUrl();
  }

  Future<bool> isCurrentUserBlockedBySelectedUser() async {
    try {
      // Fetch the document for the selected user from Firestore
      DocumentSnapshot selectedUserDoc = await userCollections.doc(selectedUser).get();
      print(selectedUser);

      if (selectedUserDoc.exists) {
        // Get the blockedUsers list from the selected user's document
        List<dynamic> blockedUsers = selectedUserDoc['blockedUsers'] ?? [];

        // Check if the current user's email is in the blockedUsers list
        String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
        bool isBlocked = !blockedUsers.contains(currentUserEmail);

        return isBlocked;
      } else {
        // If the selected user's document does not exist, assume not blocked
        return false;
      }
    } catch (e) {
      print("Error checking if current user is blocked: $e");
      return false; // In case of error, assume not blocked for safety
    }
  }


  Future<void> getImageUrl () async {
    setState(() {
      isLoading = true;
    });
    try {
      final ref = storage.ref().child(selectedUser);
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
    print(selectedUser) ;
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

  addUserToBlock() async {
    // Fetch the current user's document to check the Friends list.
    var currentUserDoc = await userCollections.doc(currentUser.email).get();
    var friendsList = currentUserDoc.data()?['Friends'] ?? [];

    // Check if the selectedUser is in the current user's Friends list.
    bool isFriend = friendsList.contains(selectedUser);

    if(isFriend){
      // If the user is a friend, remove them from the Friends list.
      await userCollections.doc(currentUser.email).update({
        "Friends": FieldValue.arrayRemove([selectedUser])
      });
    } else {
      // Optionally handle the case where the user is not found in the Friends list.
      print("$selectedUser is not in your Friends list.");
    }
  if(! await isUserBlocked()){
      await userCollections.doc(currentUser.email).update({"blockedUsers": FieldValue.arrayUnion([selectedUser])},);
    }
    else {
      await userCollections.doc(currentUser.email).update({"blockedUsers": FieldValue.arrayRemove([selectedUser])},);
    }
    Navigator.of(context).pop(context);
  }


  Future<bool> isUserBlocked() async {
    DocumentSnapshot userDoc = await userCollections.doc(FirebaseAuth.instance.currentUser!.email).get();
    var blockedUsersField = userDoc.get('blockedUsers');

    // Check the type of blockedUsersField and act accordingly
    if (blockedUsersField is List<dynamic>) {
      // If it's a list, cast each element to a String (safely)
      List<String> blockedUsers = List<String>.from(blockedUsersField.map((item) => item.toString()));
      return blockedUsers.contains(selectedUser);
    } else if (blockedUsersField is String) {
      // If it's a single string, compare directly (this might be an edge case)
      return blockedUsersField == selectedUser;
    } else {
      // If blockedUsersField is null or another unexpected type, return false
      return false;
    }
  }



  Future<void> block() async {
    if (await isUserBlocked()) {
      print ('test');
      await showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
              backgroundColor: theme,
              title: Text(
                "Would you like to unblock this user?",
                style: const TextStyle(
                    color: Colors.white, fontFamily: 'sfPro'),
              ),
              actions: [
                //cancel button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(
                      color: Colors.white, fontFamily: 'sfPro'),),),
                //save button
                TextButton(
                  onPressed: () => addUserToBlock(),
                  child: Text('Unblock', style: TextStyle(
                      color: Colors.white, fontFamily: 'sfPro'),),),
              ],
            ),
      );
    }
    else {
      await showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
              backgroundColor: theme,
              title: Text(
                "Would you like to block this user?",
                style: const TextStyle(
                    color: Colors.white, fontFamily: 'sfPro'),
              ),
              actions: [
                //cancel button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(
                      color: Colors.white, fontFamily: 'sfPro'),),),
                //save button
                TextButton(
                  onPressed: () => addUserToBlock(),
                  child: Text('Block', style: TextStyle(
                      color: Colors.white, fontFamily: 'sfPro'),),),
              ],
            ),
      );
      //update in firestore
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: theme,
          actions: [
            IconButton(
              onPressed: block,
              icon: Icon(Icons.more_horiz), color: Colors.white,),
          ],
        ),
        body: Container(
          color: theme2,
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('Users').doc(selectedUser).snapshots(),
            builder: (context, snapshot){
              if (snapshot.hasData) {
                //get user data
                final userData = snapshot.data!.data() as Map<String, dynamic>;
                return ListView(
                  children: [
                    const SizedBox(height: 50),
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      placeholder: (context, url) => CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                      imageBuilder: (context, imageProvider) => Container(
                        width: 240,  // Set the size to what you need
                        height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.fitWidth,  // Here you can use any BoxFit property
                          ),
                        ),
                      ),

                    ),
                    const SizedBox(height: 20,),

                    /*Text(
                        selectedUser!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.amber),
                      ),*/

                    const SizedBox(height: 10,),

                    Center(
                      child: InkWell(
                        onTap: () async {
                          if(await isCurrentUserBlockedBySelectedUser()){
                            try {
                              userCollections.doc(currentUser.email!).update({
                                'Friends': FieldValue.arrayUnion([selectedUser])
                              });
                              userCollections.doc(selectedUser).update({
                                'Friends': FieldValue.arrayUnion([currentUser.email!])
                              });
                              Navigator.push(
                                context, MaterialPageRoute(builder: (context) => HomePage()),
                              );
                            } catch (e) {
                              print("Error adding friend: $e");
                            }
                          }
                          selectedUser = '';
                        },
                        // Rest of your InkWell properties...

                        child: Text(
                          'Direct Message',
                          style: TextStyle(color: theme3),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20,),

                    Padding(
                      padding: const EdgeInsets.only(left:25),
                      child: Text(
                        'My Details',
                        style: TextStyle(color: theme3),
                      ),
                    ),
                    //username
                    MyTextBox2(
                      text2: userData ['username'],
                      sectionName2: "Username",
                    ),
                    MyTextBox2(
                      text2: userData ['bio'],
                      sectionName2: "Bio",
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
                            itemBuilder: (context, index) => Icon(Icons.star, color: theme3),
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
                            itemBuilder: (context, index) => Icon(Icons.star, color: theme3),
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
        )
    );
  }
}

