import 'package:classchat/components/delete_button.dart';
import 'package:classchat/components/like_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:classchat/auth/constants.dart';

class WallPost extends StatefulWidget {
  final String userEmail;
  final String message;
  final String imgUrl;
  final String currentUserName;
  //final String time;
  final String postId;
  final List<String> likes;
  const WallPost({
    super.key,
    required this.imgUrl,
    required this.userEmail,
    required this.message,
    required this.currentUserName,
    required this.postId,
    required this.likes,
    //required this.time,
  });

  @override
  State<WallPost> createState() => _WallPostState();
}

class _WallPostState extends State<WallPost> {
  final userEmail = FirebaseAuth.instance.currentUser!;
  final currentUserName = FirebaseFirestore.instance.collection('Users').doc(currentEmail).get().then((value) => value['username']);
  bool isLiked = false;
  final storage = FirebaseStorage.instance;
  late String imageUrl = '';
  //String currentUsername = FirebaseAuth.instance.currentUser!.email!;


  Future<void> getImageUrl () async {
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
    isLiked =  widget.likes.contains(currentEmail);
  }

  void toggleLike(){
    setState(() {
      isLiked = !isLiked;
    });
    DocumentReference postRef = FirebaseFirestore.instance.collection('User Posts').doc(widget.postId);

    if (isLiked) {
      postRef.update({
        'Likes' : FieldValue.arrayUnion([currentEmail])
      });
    } else{
      postRef.update({
        'Likes' : FieldValue.arrayRemove([currentEmail])
      });
    }
    print(currentUser!.displayName!)  ;
  }
  //delete post
  void deletePost() {
    //show dialogue box to confirm confirmation
    showDialog(
        context: context,
        builder: (context)=>AlertDialog(
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post?'),
          actions: [
            //cancel button
            TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Cancel')),
            //confirm button
            TextButton(
                onPressed: () async {
                  FirebaseFirestore.instance.collection('User Posts' + currentClass + dmID).doc(widget.postId).delete();
                  Navigator.pop(context);
                },
                child: const Text('Delete'))
          ],
        ),);
  }

  String getUserId() {
    String currentUsername = '';
    FirebaseFirestore.instance.collection('Users').doc(currentEmail).get().then((value) {
      currentUsername = value['username'];
    });
    print(currentUsername)  ;
    return currentUsername;
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.pink.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: EdgeInsets.only(top: 15, left: 15, right: 15),
      padding: EdgeInsets.all(15),
      child: Row(
        children: [
          //profile pic
          CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage(
                imageUrl != '' ? imageUrl : 'https://www.pngitem.com/pimgs/m/30-307416_profile-icon-png-image-free-download-searchpng-employee.png',
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
                  widget.likes.length.toString(),
                  ),
              const SizedBox(height:10),
              if (widget.userEmail == currentEmail)
                DeleteButton(onTap: deletePost),
            ],
          ),
          const SizedBox(width: 20,),
          //wallpost
          Expanded(
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.currentUserName,
                      style: TextStyle(color: Colors.black, fontFamily: 'sfProSemiBold', fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.5,
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
