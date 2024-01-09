import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

FirebaseFirestore _firestore = FirebaseFirestore.instance;
User? currentUser = FirebaseAuth.instance.currentUser;
String currentClass = '';
String selectedUser = '';
String dmID = '';



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


bool classesRegistered = false;