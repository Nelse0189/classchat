import 'package:cached_network_image/cached_network_image.dart';
import 'package:classchat/friend_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '/auth/constants.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:shimmer/shimmer.dart';
class SearchPage extends StatefulWidget {

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, String> imagesMap = {};
  Timer? _debounce;
  bool isLoading = false;
  final storage = FirebaseStorage.instance;
  late String imageUrl = '';
  final Map<String, Future<String>> _imageUrlsCache = {};

  Future<String> _getCachedImageUrl(String user) {
    if (!_imageUrlsCache.containsKey(user)) {
      _imageUrlsCache[user] = getImageUrl(user);
    }
    return _imageUrlsCache[user]!;
  }

  Future<String> getImageUrl(String user) async {
    final ref = storage.ref().child(user);
    final url = await ref.getDownloadURL();
    setState(() {
      imageUrl = url;
    });
    return imageUrl;
  }

  goToFriendPage(String friend){
    selectedUser = friend;
    Navigator.push(context, MaterialPageRoute(builder: (context)=> FriendProfilePage()));
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
    Map<String, String> imagesMap = {
    }; // Create a Map to hold userID to imageURL mappings

    for (var userDoc in users) {
      String userID = userDoc.id;
      String userName = userDoc['username'];
      if (userID != FirebaseAuth.instance.currentUser!
          .email) { // Check to exclude current user
        userNames.add(userName);
        String imageUrl = await getImageUrl(userID); // Fetch image URL
        imagesMap[userID] = imageUrl; // Associate image URL with userID
      }
    }

    // Remove current user from the lists if needed, handled by the if check above

    permUsers =
        List.from(users); // Clone users to permUsers if needed for resetting
    setState(() {
      isLoading = false;
      this.imagesMap = imagesMap; // Store the imagesMap in the state
    });
  }

  List<String> _foundedUsers = [];


  @override
  void initState() {
    //getImageUrl();
    //getUsers();
    super.initState();
    setState(() {
      _foundedUsers = [];
    });
  }

  @override
  void dispose() {
    // Perform cleanup tasks here
    _searchController.dispose();
    super.dispose(); // It's important to call super.dispose() at the end
  }


  /*onSearch(String search) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      if (search.isNotEmpty) {
        setState(() => isLoading = true); // Show loading indicator at the start of search
        // Load users if they haven't been loaded yet
        if (users.isEmpty) {
          await getUsers(); // This already sets isLoading to false when done
        }
        setState(() {
          _foundedUsers = userNames.where((user) => user.toLowerCase().startsWith(search.toLowerCase())).toList();
          users = permUsers.where((user) => user['username'].toLowerCase().startsWith(search.toLowerCase())).toList();
          isLoading = false; // Hide loading indicator after filtering users
        });

      } else {
        setState(() {
          _foundedUsers = [];
          users = [];
          isLoading = false; // Also ensure loading indicator is hidden when search is cleared
        });
      }
    });
  }*/

  Future<void> onSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _foundedUsers = [];
        isLoading = false;
      });
      return;
    }

    setState(() => isLoading = true);

    final searchQuery = query.toLowerCase();
    final querySnapshot = await FirebaseFirestore.instance
        .collection('Users')
    // Use where to search for usernames starting with the query
    // Assuming 'username_lowercase' is a field that stores the username in lowercase
        .where('username_lowercase', isGreaterThanOrEqualTo: searchQuery)
        .where(
        'username_lowercase', isLessThanOrEqualTo: searchQuery + '\uf8ff')
        .get();

    final results = querySnapshot.docs;

    // Assuming you want to update _foundedUsers and users with results
    setState(() {
      _foundedUsers = results.map((doc) => doc['username'] as String).toList();
      users = results;
      isLoading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, //remove back button
        elevation: 0,
        backgroundColor: theme,
        title: Container(
          height: 38,
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              if (_debounce?.isActive ?? false) _debounce!.cancel();
              _debounce = Timer(const Duration(milliseconds: 600), () {
                onSearch(value);
              });
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: EdgeInsets.all(0),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey.shade600,
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
        color: theme2,
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: theme2,))
            : _foundedUsers.isNotEmpty
            ? ListView.builder(
          itemCount: _foundedUsers.length,
          itemBuilder: (context, index) {
            final userName = _foundedUsers[index];
            final userDoc = users.firstWhereOrNull((doc) => doc['username'] == userName);

            if (userDoc == null) {
              return ListTile(
                title: Text(userName),
                subtitle: Text("User not found"),
              );
            } else {
              final userID = userDoc.id;

              return FutureBuilder<String>(
                future: _getCachedImageUrl(userID),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator(
                      color: theme2,
                    ); // Placeholder for loading state
                  } else if (snapshot.hasError) {
                    return Icon(Icons.error); // Placeholder for error state
                  } else {
                    // Assuming snapshot.data contains the URL
                    return ListTile(
                      leading: Stack(
                        children: [CachedNetworkImage(
                          imageUrl: snapshot.data ?? 'default_image_url',
                          placeholder: (context, url) => CircularProgressIndicator(),
                          errorWidget: (context, url, error) => Icon(Icons.error),
                          imageBuilder: (context, imageProvider) => CircleAvatar(
                            radius: 25,
                            backgroundImage: imageProvider,
                          ),
                        ),
                          Positioned.fill(
                            child: Shimmer.fromColors(
                              baseColor: Colors.white.withOpacity(0.1),
                              highlightColor: Colors.white.withOpacity(0.3),
                              child: Container(
                                color: Colors.white,
                                child: const SizedBox.expand(), // This covers the image area
                              ),
                            ),
                          ),
                      ],
                      ),
                      contentPadding: EdgeInsets.fromLTRB(-10, 0, 0, 0),
                      title: Text(userDoc['username'], style: TextStyle(fontFamily: 'sfPro', color: Colors.black, fontSize: 16)),
                      subtitle: Text('online'),
                      trailing: Icon(Icons.message),
                      onTap: () {
                        // Handle onTap
                        goToFriendPage(userDoc.id);
                      },
                    );
                  }
                },
              );
            }
          },
        ) : Shimmer.fromColors(
          baseColor: Colors.grey[300]!, // Adjust the shimmer base color
          highlightColor: Colors.grey[100]!, // Adjust the shimmer highlight color
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(0, 15, 0, 0),
            itemCount: 12, // Number of shimmer items
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10,),
                  Container(
                    width: 55.0,
                    height: 55.0,
                    color: Colors.white,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: double.infinity,
                          height: 10.0,
                          color: Colors.white,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 2.0),
                        ),
                        Container(
                          width: double.infinity,
                          height: 10.0,
                          color: Colors.white,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 2.0),
                        ),
                        Container(
                          width: 40.0,
                          height: 8.0,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}