import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './auth/auth.dart';
import 'message_page.dart';
import 'auth/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'auth/login_page.dart';
import 'marketplace_item.dart';
import 'marketplace.dart';
import 'itemdetailpage.dart';
import 'package:shimmer/shimmer.dart';
class ClassPage extends StatefulWidget {
  const ClassPage({super.key});

  @override
  State<ClassPage> createState() => _ClassPageState();
}

class _ClassPageState extends State<ClassPage> {

  List<String> users = [];
  int userCount = 0;
  bool isLoading = true;
  final storage = FirebaseStorage.instance;
  late String imageUrl = '';
  Map<String, String> emailImageUrls = {};

  @override
  void initState() {
    super.initState();
    if(currentUser!=null) {
      getUserTheme();
    }
  }

  Future<List<MarketplaceItem>> getRecentUploadedItems() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('items') // Assume your items are stored in a collection named 'Items'// Assuming each item has a 'title' field
        .limit(10) // Adjust the number to how many items you want to fetch
        .get();

    List<MarketplaceItem> items = querySnapshot.docs.map((doc) {
      return MarketplaceItem.fromDocument(doc);
    }).toList();

    return items;
  }


  void signOut(){
    currentUser = null;
    FirebaseAuth.instance.signOut();
    Navigator.push(context,MaterialPageRoute(builder: (context) => LoginPage(),),);
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

  Future<void> getImageUrl(String email) async {
    if (emailImageUrls.containsKey(email)) return; // URL already fetched

    try {
      final ref = storage.ref().child(email);
      final url = await ref.getDownloadURL();
      setState(() {
        emailImageUrls[email] = url; // Store the URL
      });
    } catch (e) {
      print("Error fetching image URL: $e");
      // Optionally, handle errors, e.g., by setting a default image URL
    }
  }

  Future <void> messageSeller(context, widget)async{

    Navigator.push(
      context, MaterialPageRoute(builder: (context) => ItemDetailPage(item: widget)),
    );



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

  String formatPrice(String priceCents) {
    // Convert the price from a string to an integer
    int cents = int.parse(priceCents);
    // Convert cents to a decimal number representing dollars
    double dollars = cents / 100.0;
    // Format the number as a string with two decimal places
    return dollars.toStringAsFixed(2);
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: theme2,
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          backgroundColor: theme,
          titleTextStyle: TextStyle(fontFamily: 'sfPro', color: Colors.white, fontSize: 20),
          title: Shimmer.fromColors(
            period: Duration(milliseconds: 1500), // Adjust duration to control the speed of the shimmer effect
            baseColor: Colors.white, // Base color of the text
            highlightColor: Colors.grey[300]!, // Shimmer highlight color
            child: Text(
              'Skubble',
              style: TextStyle(
                fontFamily: 'SfProBold',
              ),
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: signOut,
              icon: Icon(Icons.logout),
              color: Colors.white,
            ),
          ],
        ),
      drawer: Drawer(
            backgroundColor: theme,
            child: Column(
                children: [
                  SizedBox(
                    height: 50,
                  ),
                  Container(
                    height: 50,
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
                    alignment: Alignment.centerLeft,
                    color: Colors.grey.shade900,
                    child: Row(
                      children: [
                        Text('Direct Messages', style: TextStyle(fontFamily: 'sfPro', color: theme3, fontSize: 20),),
                        SizedBox(width: 10,),
                        IconButton(onPressed: (){}, icon: Icon(Icons.person_3_outlined, color: theme3,))
                      ],
                    ),
                  ),
                  Expanded(
                    child: FirebaseAuth.instance.currentUser != null
          ? StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(FirebaseAuth.instance.currentUser!.email)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else {
                  final data = snapshot.data!.data() as Map<String, dynamic>?; // Cast the data to the correct type
                  if (data == null) {
                    return const Center(
                      child: Text("No data available"),
                    );
                  }
                  final friendsList = data['Friends'] as List<dynamic>?; // Safely access the Friends list
                  if (friendsList == null || friendsList.isEmpty) {
                    return const Center(
                      child: Text("No friends found"),
                    );
                  }
                  return ListView.builder(
                    itemCount: friendsList.length,
                    itemBuilder: (context, index) {
                      final friendEmail = friendsList[index];
                      if (!emailImageUrls.containsKey(friendEmail)) {
                        getImageUrl(friendEmail);
                      }
                      return FutureBuilder<String>(
                        future: getUsernameFromEmail(friendEmail),
                        builder: (context, asyncSnapshot) {
                          if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                            return ListTile(
                              title: Text('Loading...', style: TextStyle(color: Colors.white)),
                            );
                          } else if (asyncSnapshot.hasData) {
                            final imageUrl = emailImageUrls[friendEmail] ?? '';
                            return ListTile(
                              trailing: CachedNetworkImage(
                                imageUrl: imageUrl,
                                placeholder: (context, url) => CircularProgressIndicator(),
                                errorWidget: (context, url, error) => Icon(Icons.error),
                                imageBuilder: (context, imageProvider) => CircleAvatar(
                                  radius: 25,
                                  backgroundImage: imageProvider,
                                ),
                              ),
                              title: Text(asyncSnapshot.data!, style: TextStyle(fontFamily: 'sfProSemiBold', color: Colors.white, fontSize: 16)),
                              onTap: () {
                                selectedUser = friendsList[index]; // Assuming this is the correct value you needed
                                // Replace HomePage with the actual page you want to navigate to
                                Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
                              },
                            );
                          } else {
                            return ListTile(
                              title: Text('Error fetching data', style: TextStyle(color: Colors.white)),
                            );
                          }
                        },
                      );
                    },
                  );
                }
              },
            )
          : Center(
              child: Text(
                "Please sign in to view this content.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
                  )
                ]
            )
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
             Column(
                children: [
                  // This Container will serve as the "UConn AllChat" tile with a background image
                  InkWell(
                                    onTap: () {
                                      currentClass = 'UConn AllChat';
                                      print (currentClass);
                                      Navigator.push(context,MaterialPageRoute(builder: (context) => HomePage(),),);
                                    },
                                    child: Container(
                                      width: double.infinity, // Span the container full width
                                      height: MediaQuery.of(context).size.height * 0.2, // 20% of the screen height
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: AssetImage("images/uconn.jpg"), // Replace with your image
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text('UConn Chat', style: TextStyle(fontFamily: 'sfPro', color: Colors.white,  fontSize: 24)),
                                      ),

                                    ),
                                  ),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(bottom: 10.0,top: 10),
                    child: Center(child: Text('Recently Uploaded Items', style: TextStyle(fontSize: 16, color: Colors.white))),
                    color: theme,
                  ),
                  Expanded(
                    child: FutureBuilder<List<MarketplaceItem>>(
                      future: getRecentUploadedItems(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text("Error loading items: ${snapshot.error}"));
                        } else if (snapshot.hasData) {
                          return ListView.builder(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              MarketplaceItem item = snapshot.data![index];
                              return InkWell(
                                onTap: () async {
                                  await messageSeller(context, item);
                                },
                                child: ListTile(
                  minVerticalPadding: 20,
                  leading: ClipRRect(
                       borderRadius: BorderRadius.circular(8.0), // Adjust the radius as needed
                       child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: item.imageUrls[0],
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  width: 50, // Specify the width and height of the image
                  height: 50,
                  fit: BoxFit.cover, // Ensure the image covers the area without stretching
                ),
                Positioned.fill(
                  child: Shimmer.fromColors(
                    baseColor: Colors.white.withOpacity(0.2),
                    highlightColor: Colors.white.withOpacity(0.4),
                    child: Container(
                      color: Colors.white,
                      child: const SizedBox.expand(), // This covers the image area
                    ),
                  ),
                ),
              ],
                       ),
                  ),
                  title: Text(item.title),
                  subtitle: Text(
                       "\$${formatPrice(item.price)} - ${item.description} - ${item.sellerName}",
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                  ),
                  // Add onTap or other interactions as needed
                ),

                              );
                            },
                          );
                        } else {
                          return Center(child: Text("No items found"));
                        }
                      },
                    ),
                  ),

                ]
                       ),
  ],
           ),
        );

  }
}
