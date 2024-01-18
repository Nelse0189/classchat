import 'package:classchat/friend_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '/auth/constants.dart';
import 'package:firebase_storage/firebase_storage.dart';
class SearchPage extends StatefulWidget {

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>{
  bool isLoading = true;
  final storage = FirebaseStorage.instance;
  late String imageUrl = '';

  Future<String> getImageUrl (String user) async {
    final ref = storage.ref().child(user);
    final url = await ref.getDownloadURL();
    setState(() {
      imageUrl = url;
    });
    return imageUrl;
  }
  //create list of user documents from firestore
  final userCollections = FirebaseFirestore.instance.collection('Users');
  List<DocumentSnapshot> users = [];
  List<String> userNames = [];
  List<DocumentSnapshot> permUsers = [];
  List<String> imgList = [];
  String url = '';
  //store users in firestore within a list
  Future<void> getUsers() async {
    isLoading = true;
    QuerySnapshot querySnapshot = await userCollections.get();
    users = querySnapshot.docs;
    for (int i = 0; i < users.length; i++) {
      userNames.add(users[i]['username']);
      imgList.add(await getImageUrl(users[i].id));
    }
    for(int i = 0; i < users.length; i++){
      if(users[i].id == FirebaseAuth.instance.currentUser!.email){
        userNames.removeAt(i);
        users.removeAt(i);
        imgList.removeAt(i);
      }
    }
    permUsers = users;
    setState(() {
      isLoading = false;
    });
  }
  List<String> _foundedUsers = [];


  @override
  void initState() {
    //getImageUrl();
    getUsers();
    super.initState();
    setState((){
      _foundedUsers = userNames;
    });

  }

  onSearch(String search) async {
    for (int i = 0; i < users.length; i++) {
      url = await getImageUrl(users[i].id);
    }
    setState(() {
      _foundedUsers = userNames.where((user) => user.toLowerCase().contains(search)).toList();
      users = permUsers.where((user) => user['username'].toLowerCase().contains(search)).toList ();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: isLoading ? CircularProgressIndicator() :
      Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, //remove back button
          elevation: 0,
          backgroundColor: Colors.pink.shade500,
          title: Container(
            height: 38,
            child: TextField(
              onChanged: (value) => onSearch(value),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[850],
                contentPadding: EdgeInsets.all(0),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade500,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide.none,
                ),
                hintStyle: TextStyle(
                  fontSize: 14,
                  fontFamily: 'sfPro',
                  color: Colors.grey.shade500,
                ),
                hintText: 'Search users',
      
              ),
            ),
          ),
        ),
        body: Container(
          padding: EdgeInsets.only(right: 20, left: 20),
          color: Colors.pink.shade300,
          child: _foundedUsers.length > 0 ? ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].id!;
              final imageUrl = index < imgList.length ? imgList[index] : 'https://www.pngitem.com/pimgs/m/30-307416_profile-icon-png-image-free-download-searchpng-employee.png';
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                    imageUrl,
                  ),
                ),
                title: Text(
                    users[index]['username']),
                subtitle: Text('online'),
                trailing: Icon(Icons.message),
                onTap: () {
                  selectedUser = users[index].id;
                  Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfilePage(),),);;
                }
              );
            },
          ) : Center(child: Text("No users found", style: TextStyle(color: Colors.white, fontFamily: 'sfPro', fontSize: 15),),),
        ),
      ),
    );
  }
}