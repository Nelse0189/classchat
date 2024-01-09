import 'package:classchat/components/delete_button.dart';
import 'package:classchat/components/like_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:classchat/auth/constants.dart';

class WallPost extends StatefulWidget {
  final String message;
  final String user;
  //final String time;
  final String postId;
  final List<String> likes;
  const WallPost({
    super.key,
    required this.message,
    required this.user,
    required this.postId,
    required this.likes,
    //required this.time,
  });

  @override
  State<WallPost> createState() => _WallPostState();
}

class _WallPostState extends State<WallPost> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  bool isLiked = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isLiked =  widget.likes.contains(currentUser.email);
  }

  void toggleLike(){
    setState(() {
      isLiked = !isLiked;
    });
    DocumentReference postRef = FirebaseFirestore.instance.collection('User Posts').doc(widget.postId);

    if (isLiked) {
      postRef.update({
        'Likes' : FieldValue.arrayUnion([currentUser.email])
      });
    } else{
      postRef.update({
        'Likes' : FieldValue.arrayRemove([currentUser.email])
      });
    }
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


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: EdgeInsets.only(top: 25, left: 25, right: 25),
      padding: EdgeInsets.all(25),
      child: Row(
        children: [
          //profile pic
          //Container(
            //decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red[400]),
            //padding: EdgeInsets.all(10),
            //child: const Icon(Icons.person,
            //color: Colors.white,
            //),
          //),
          Column(
            children: [
              //like button
              LikeButton(isLiked: isLiked, onTap: toggleLike),
              const SizedBox(height: 5),
              //Amount of likes text
              Text(widget.likes.length.toString())
            ],
          ),
          const SizedBox(width: 20,),
          //wallpost
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user,
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  const SizedBox(height: 10),
                  Text(widget.message),
                ],
              ),
              //delete button
              if (widget.user == currentUser.email)
                DeleteButton(onTap: deletePost),
              
            ],
          ),
        ],
      ),
    );
  }
}
