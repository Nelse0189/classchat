
import 'package:classchat/auth/auth.dart';
import 'package:classchat/components/wall_post.dart';
import 'package:classchat/main.dart';
import 'package:classchat/text_field.dart';
import 'package:classchat/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'auth/constants.dart';
import 'class_page.dart';
import 'search_page.dart';
import 'resources/add_data.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';
import 'class_page.dart';
import 'auth/constants.dart';
import 'auth/register_page.dart';
import 'package:shimmer/shimmer.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});



  @override
  State<HomePage> createState() => _HomePageState();
}



class _HomePageState extends State<HomePage> {
  Uint8List? _image;
  String _imageUrl = '';
  String userID = '';

  @override
  void initState() {
    super.initState();
    getUserId();
    if(currentUser!=null){
      final currentUser = FirebaseAuth.instance.currentUser!;
    }
    if(selectedUser!='' && currentUser!=null) {
      generateDMID(FirebaseAuth.instance.currentUser!.email!);
    }
    print(currentClass + dmID);
    textController.addListener(() {
      // Example of filtering specific words
      String filteredText = filterBadWords(textController.text);
      if (textController.text != filteredText) {
        textController.text = filteredText;
        textController.selection = TextSelection.fromPosition(TextPosition(offset: filteredText.length)); // Reset cursor position
      }
    });
  }

  final textController = TextEditingController();

  String generateRandomString(int len) {
    var r = Random();
    const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
    return List.generate(len, (index) => _chars[r.nextInt(_chars.length)]).join();
  }

  String filterBadWords(String text) {
    // Example: Simple word filtering
    List<String> badWords = ["penis", "vagina", "dick", "cock", "faggot", "nigger", "nigga", "chink", "kike"]; // Define bad words
    String filteredText = text;
    for (String word in badWords) {
      filteredText = filteredText.replaceAll(word, "*".padRight(word.length, '*')); // Replace bad words with asterisks
    }
    return filteredText;
  }

  void signOut(){
    FirebaseAuth.instance.signOut();
    Navigator.push(context,MaterialPageRoute(builder: (context) => AuthPage(),),);
  }

  Future<Uint8List?> compressImage(Uint8List fileBytes) async {
    try {
      final Uint8List? result = await FlutterImageCompress.compressWithList(
        fileBytes,
        minWidth: 1080, // Adjust the settings as needed
        minHeight: 720,
        quality: 50, // Adjust the quality
      );
      return result;
    } catch (e) {
      print("Error compressing image: $e");
      return null;
    }
  }

  void selectImage() async {
    final Uint8List? img = await compressImage( await pickImage(ImageSource.gallery));
    if (img != null) {
      setState(() {
        _image = img;
      });
    }
  }

  void onPostDeleted() {
    setState(() {
      // Increment the signal to trigger StreamBuilder rebuild
      refreshSignal++;
    });
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
    if(selectedUser!='') {
      generateDMID(FirebaseAuth.instance.currentUser!.email!);
    }
    String trimmedText = textController.text.trim();
    if(trimmedText!='') {
      FirebaseFirestore.instance.collection(
          "User Posts" + currentClass + dmID).add({
        'postImgUrl': _imageUrl,
        'currentUserName': currentUsername,
        'imgUrl': currentUser!.email,
        'UserEmail': currentUser!.email,
        "Message": textController.text,
        'TimeStamp': FieldValue.serverTimestamp(),
        'Likes': [],
        'reports': [],
      });
    }

    setState(() {
      textController.clear();
      _image = null;
      _imageUrl = '';
    });
  }


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // User not signed in, return a message or redirect to a sign-in page
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black), // Customize color as needed
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0, // Removes the shadow under the app bar
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
            Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Please sign in to access this page.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20), // Provides space between the text and the button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50), // Adjust padding as needed
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterPage()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme, // Button color, // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15), // Button padding
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Text('Register'),
                  ),
                ),
              ],
            ),
          ),
                ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme,
        title: Text('Skubble', style: TextStyle(fontFamily: 'sfProBold'),),
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
          color: Colors.white70,
          child: Column(
            children: [
              StreamBuilder(
                key: ValueKey(refreshSignal),
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
                            reports: List<String>.from(post['reports'] ?? []),
                            onPostDeleted: onPostDeleted,
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
                        hintText: "Type your message...",
                        obscureText: false,
                      ),
                    ),
                    //Post Button
                    IconButton(onPressed: postMessage, icon: const Icon(Icons.arrow_circle_up)),
                    IconButton(onPressed: selectImage, icon: const Icon(Icons.add_a_photo)),
                  ],
                ),
              ),

              //Text("Logged in as: " + currentUser.email!),
              //const SizedBox(height: 30),
            ],
          ),
        ),
    ],
      ),
    );
  }
}
  