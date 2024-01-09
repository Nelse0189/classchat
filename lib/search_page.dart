import 'package:classchat/friend_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '/auth/constants.dart';
class SearchPage extends StatefulWidget {

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>{
  //create list of user documents from firestore
  final userCollections = FirebaseFirestore.instance.collection('Users');
  List<DocumentSnapshot> users = [];
  List<String> userNames = [];
  //store users in firestore within a list
  Future<void> getUsers() async {
    QuerySnapshot querySnapshot = await userCollections.get();
    users = querySnapshot.docs;
    for (int i = 0; i < users.length; i++) {
      userNames.add(users[i]['username']);
    }
    for(int i = 0; i < users.length; i++){
      if(users[i].id == FirebaseAuth.instance.currentUser!.email){
        userNames.removeAt(i);
      }
    }
  }
  List<String> _foundedUsers = [];

  @override
  void initState() {
    getUsers();
    super.initState();
    setState((){
      _foundedUsers = userNames;
    });
  }

  onSearch(String search) {
    setState(() {
      _foundedUsers = userNames.where((user) => user.toLowerCase().contains(search)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, //remove back button
        elevation: 0,
        backgroundColor: Colors.grey.shade900,
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
                color: Colors.grey.shade500,
              ),
              hintText: 'Search users',

            ),
          ),
        ),
      ),
      body: Container(
        padding: EdgeInsets.only(right: 20, left: 20),
        color: Colors.grey.shade900,
        child: _foundedUsers.length > 0 ? ListView.builder(
          itemCount: _foundedUsers.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: CircleAvatar(
              ),
              title: Text(
                  _foundedUsers[index]),
              subtitle: Text('online'),
              trailing: Icon(Icons.message),
              onTap: () {
                selectedUser = users[index].id;
                Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfilePage(),),);;
              }
            );
          },
        ) : Center(child: Text("No users found", style: TextStyle(color: Colors.white),)),
      ),
    );
  }
}