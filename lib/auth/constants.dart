import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

FirebaseFirestore _firestore = FirebaseFirestore.instance;
User? currentUser = FirebaseAuth.instance.currentUser;
String currentClass = '';
String selectedUser = '';
String dmID = '';
String currentUsername = '';
String currentEmail = FirebaseAuth.instance.currentUser!.email!;

final userCollections = FirebaseFirestore.instance.collection('Users');
List<DocumentSnapshot> users = [];
List<DocumentSnapshot> permUsers = [];

Future<String> getUserId() async {
  QuerySnapshot querySnapshot = await userCollections.get();
  users = querySnapshot.docs;
  for (int i = 0; i < users.length; i++) {
    if (users[i].id == FirebaseAuth.instance.currentUser!.email) {
      currentUsername = users[i]['username'];
      users.add(users[i]['username']);
    }
  }
  return currentUsername;
}

nullifyCurrentClass() {
  currentClass = '';
}

generateDMID(currentUser) {
  if (currentUser!.compareTo(selectedUser) < 0) {
    dmID = currentUser! + selectedUser;
  } else {
    dmID = selectedUser + currentUser!;
  }
    print(dmID);
}

nullifyDMID() {
  dmID = '';
}

nullifySelectedUser() {
  selectedUser = '';
}


bool classesRegistered = false;