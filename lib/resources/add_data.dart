import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final FirebaseStorage _storage = FirebaseStorage.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class StoreData {
  // This function compresses the image file before uploading
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

  Future<String> uploadImageToStorage(String childName, Uint8List file) async {
    Reference ref = _storage.ref().child(childName);
    UploadTask uploadTask = ref.putData(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<String> saveData({
    required Uint8List file,
  }) async {
    String resp = "Some Error Occurred";
    try {
      // Compress the image first
      Uint8List? compressedFile = await compressImage(file);
      if (compressedFile != null) {
        String imageUrl = await uploadImageToStorage(FirebaseAuth.instance.currentUser!.email!, compressedFile);
        await _firestore.collection(FirebaseAuth.instance.currentUser!.email!).add({
          'imageLink': imageUrl,
        });
        resp = 'success';
      } else {
        resp = "Image compression failed";
      }
    } catch (err) {
      resp = err.toString();
    }
    print(resp);
    return resp;
  }
}
