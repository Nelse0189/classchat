import 'dart:typed_data';
import 'package:classchat/auth/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:classchat/auth/constants.dart';

final FirebaseStorage _storage = FirebaseStorage.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class StoreData {
  Future<String> uploadImageToStorage(String childName,Uint8List file) async {
    Reference ref = _storage.ref().child(childName);
    UploadTask uploadTask = ref.putData(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<String> saveData({
    required Uint8List file,
  }) async {
    String resp = " Some Error Occurred";
    try{
        String imageUrl = await uploadImageToStorage(FirebaseAuth.instance.currentUser!.email!, file);
        await _firestore.collection(FirebaseAuth.instance.currentUser!.email!).add({
          'imageLink': imageUrl,
        });

        resp = 'success';
        print(resp);
    }
    catch(err){
      resp =err.toString();
    }
    print (resp);
    return resp;
  }
}