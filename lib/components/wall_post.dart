import 'package:cached_network_image/cached_network_image.dart';
import 'package:classchat/components/delete_button.dart';
import 'package:classchat/components/like_button.dart';
import 'package:classchat/friend_profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:classchat/auth/constants.dart';
import 'package:classchat/full_screen_image.dart';

class WallPost extends StatefulWidget {
  final String userEmail;
  final String message;
  final String imgUrl;
  final String currentUserName;
  final String postImgUrl;
  final VoidCallback onPostDeleted;
  //final String time;
  final String postId;
  final List<String> Likes;
  final List<String> reports;
  const WallPost({
    Key? key,
    required this.postImgUrl,
    required this.imgUrl,
    required this.userEmail,
    required this.message,
    required this.currentUserName,
    required this.postId,
    required this.Likes,
    required this.onPostDeleted,
    required this.reports,
    //required this.time,
  }) : super(key:key);

  @override
  State<WallPost> createState() => _WallPostState();
}

class _WallPostState extends State<WallPost> {

  final userEmail = FirebaseAuth.instance.currentUser!.email;
  final currentUserName = FirebaseFirestore.instance.collection('Users').doc(
      currentEmail).get().then((value) => value['username']);
  bool isLiked = false;
  final storage = FirebaseStorage.instance;
  late String postImgUrl = '';
  late String imageUrl = '';
  Color reportColor = Colors.orange;

  //String currentUsername = FirebaseAuth.instance.currentUser!.email!;


  Future<void> getImageUrl() async {
    final ref = storage.ref().child(widget.imgUrl);
    final url = await ref.getDownloadURL();
    setState(() {
      imageUrl = url;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getImageUrl();
    isLiked = widget.Likes.contains(userEmail);
  }

  void toggleLike() {
    setState(() {
      isLiked = !isLiked;
    });
    currentEmail = FirebaseAuth.instance.currentUser!.email!;
    DocumentReference postRef = FirebaseFirestore.instance.collection(
        'User Posts' + currentClass + dmID).doc(widget.postId);

    if (isLiked) {
      postRef.update({
        'Likes': FieldValue.arrayUnion([currentEmail])
      });
    } else {
      postRef.update({
        'Likes': FieldValue.arrayRemove([currentEmail])
      });
    }
  }

  //delete post
  void deletePost() {
    //show dialogue box to confirm confirmation
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Delete Post'),
            content: const Text('Are you sure you want to delete this post?'),
            actions: [
              //cancel button
              TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              //confirm button
              TextButton(
                  onPressed: () async {
                    FirebaseFirestore.instance.collection(
                        'User Posts' + currentClass + dmID)
                        .doc(widget.postId)
                        .delete();
                    widget.onPostDeleted();
                    Navigator.pop(context);
                  },
                  child: const Text('Delete'))
            ],
          ),);
  }

  String getUserId() {
    String currentUsername = '';
    FirebaseFirestore.instance.collection('Users').doc(currentEmail)
        .get()
        .then((value) {
      currentUsername = value['username'];
    });
    print(currentUsername);
    return currentUsername;
  }

  Future<void> addToReports(context) async {
    currentEmail = FirebaseAuth.instance.currentUser!.email!;
    DocumentReference postRef = FirebaseFirestore.instance.collection(
        'User Posts' + currentClass + dmID).doc(widget.postId);
    await postRef.update({"reports": FieldValue.arrayUnion([currentEmail])},);
    setState(() {
      reportColor = Colors.red;
    });
    Navigator.pop(context);
    DocumentSnapshot snapshot = await postRef.get();
    var data = snapshot.data() as Map<String,
        dynamic>?; // Cast the data to a Map
    if (data != null && data['reports'] != null) {
      List reports = data['reports'];
      if (reports.length >
          9) { // Replace someThreshold with your specific condition
        // Perform your action here, for example, disable the post or notify admins
        FirebaseFirestore.instance.collection(
            'User Posts' + currentClass + dmID).doc(widget.postId).delete();
        widget.onPostDeleted();
      }
    }
  }

  Future<void> removeReports(context) async {
    currentEmail = FirebaseAuth.instance.currentUser!.email!;
    DocumentReference postRef = FirebaseFirestore.instance.collection(
        'User Posts' + currentClass + dmID).doc(widget.postId);
    await postRef.update({"reports": FieldValue.arrayRemove([currentEmail])},);
    setState(() {
      reportColor = Colors.red;
    });
    Navigator.pop(context);
  }

  void goToFriendPage() {
    if (widget.userEmail != FirebaseAuth.instance.currentUser!.email!) {
      selectedUser = widget.userEmail;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FriendProfilePage()),);
    }
  }

  Future<Color> postColor() async {
    final currentEmail = FirebaseAuth.instance.currentUser!.email;
    // Assuming 'currentClass' and 'dmID' are available in your scope or passed as parameters
    final postRef = FirebaseFirestore.instance.collection('User Posts' + currentClass + dmID).doc(widget.postId);
    final docSnapshot = await postRef.get();

    if (docSnapshot.exists && docSnapshot.data() != null) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      final List<dynamic> reports = data['reports'] ?? [];
      // Check if the current user's email is in the reports list
      if (reports.contains(currentEmail)) {
        return Colors.red; // User has reported this post
      }
    }
    return Colors.orange; // Default color if the post is not reported by the user or if there's no data
  }


  Future<bool> isPostReported() async {
    final currentEmail = FirebaseAuth.instance.currentUser!.email;
    // Assuming 'currentClass' and 'dmID' are available in your scope or passed as parameters
    final postRef = FirebaseFirestore.instance.collection(
        'User Posts' + currentClass + dmID).doc(widget.postId);
    final docSnapshot = await postRef.get();

    if (docSnapshot.exists && docSnapshot.data() != null) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      final List<dynamic> reports = data['reports'] ?? [];
      reportColor = Colors.red;
      return reports.contains(currentEmail);
    }
    reportColor = Colors.orange;
    return false;
  }


  Future<void> report() async {
    if (!await isPostReported()) {
      await showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
              backgroundColor: theme,
              title: Text(
                "Would you like to report this post?",
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
                  onPressed: () => addToReports(context),
                  child: Text('Report', style: TextStyle(
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
              title: Text("Would you like to de-report this post?",
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
                  onPressed: () => removeReports(context),
                  child: Text('De-Report', style: TextStyle(
                      color: Colors.white, fontFamily: 'sfPro'),),),
              ],
            ),
      );
    }
  }




  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme2,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: EdgeInsets.only(top: 15, left: 15, right: 15),
      padding: EdgeInsets.all(15),
      child: Row(
        children: [

          //profile pic
          GestureDetector(
            onTap: goToFriendPage,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) => Icon(Icons.error),
              imageBuilder: (context, imageProvider) => CircleAvatar(
                  radius: 25,
                  backgroundImage: imageProvider
              ),
            ),
          ),
          const SizedBox(width: 10,),

          Column(
            children: [
              //like button
              LikeButton(isLiked: isLiked, onTap: toggleLike),
              const SizedBox(height: 5),
              //Amount of likes text
              Text(
                widget.Likes.length.toString(),
              ),
              const SizedBox(height:10),
              if (widget.userEmail == FirebaseAuth.instance.currentUser!.email!)
                DeleteButton(onTap: deletePost),
            ],
          ),
          const SizedBox(width: 15,),
          //wallpost
          Expanded(
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.currentUserName,
                          style: TextStyle(color: theme, fontFamily: 'sfProSemiBold', fontSize: 14),
                        ),

                        if(widget.userEmail != FirebaseAuth.instance.currentUser!.email!)
                          Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: EdgeInsets.only(right: 10, top: 0, left: 10), // Adjust padding as needed
                                child: InkWell(
                                  onTap: report,
                                  child: FutureBuilder<Color>(
                                    future: postColor(), // your Future<Color> method
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.done) {
                                        // When we have the color, apply it. Change to use three dots icon.
                                        return Icon(Icons.more_horiz, size: 24, color: Colors.black); // Changed to three dots icon.
                                      } else {
                                        // While waiting for the future to complete, show a placeholder or a loader
                                        return CircularProgressIndicator(); // Or some other placeholder widget
                                      }
                                    },
                                  ),
                                ),
                              )
                          )
                      ],
                    ),
                    if (widget.postImgUrl.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => FullScreenImage(imageUrl: widget.postImgUrl)),);
                        },
                        child: Image.network(
                          widget.postImgUrl,
                          width: MediaQuery.of(context).size.width * .58, // Adjust as per your UI design
                          height: 200, // Adjust as per your UI design
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.58,
                        ),
                        child: Text(
                          widget.message,
                          maxLines: 5,
                          style: TextStyle(color: Colors.black, fontFamily: 'sfPro', fontSize: 15,
                          ),),

                      ),
                    ),
                  ],
                ),
              ],

            ),
          ),
        ],
      ),
    );
  }
}

