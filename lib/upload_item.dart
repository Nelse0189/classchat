import 'dart:typed_data';
import 'package:classchat/auth/constants.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart'; // Add this import for getting directory paths
import 'resources/add_data.dart';

class ItemUploadPage extends StatefulWidget {
  final Function onItemUploaded;

  const ItemUploadPage({Key? key, required this.onItemUploaded})
      : super(key: key);

  @override
  State<ItemUploadPage> createState() => _ItemUploadPageState();
}

class PriceInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text;
    if (newText.isEmpty) return newValue;
    if (newText == '.') {
      return TextEditingValue(
        text: '0.',
        selection: TextSelection.collapsed(offset: 2),
      );
    }

    double? value = double.tryParse(newText);
    if (value == null) {
      return oldValue;
    }

    if (!newText.contains('.')) {
      newText += '.00';
    } else if (newText.split('.')[1].length < 2) {
      newText = newText.padRight(newText.length + (2 - newText.split('.')[1].length), '0');
    } else if (newText.split('.')[1].length > 2) {
      newText = newText.substring(0, newText.indexOf('.') + 3);
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: min(newText.length, newValue.selection.end)),
    );
  }
}

class _ItemUploadPageState extends State<ItemUploadPage> {
  List<String> categories = [
    'Electronics',
    'Fashion',
    'Home & Garden',
    'Sports',
    'Toys & Hobbies',
    'Motors',
    'Collectibles & Art',
    'Industrial Equipment',
  ];
  String? _selectedCategory;


  final ImagePicker _picker = ImagePicker();
  List<XFile>? _imageFiles = [];
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;

  Future<void> _pickImages() async {
    final List<XFile>? selectedImages = await _picker.pickMultiImage();
    if (selectedImages != null && selectedImages.isNotEmpty) {
      setState(() {
        _imageFiles = selectedImages;
      });
    }
  }

  Future<String?> getSellersUsername(String uid) async {
    try {
      var docSnapshot = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
      if (docSnapshot.exists && docSnapshot.data()!.containsKey('username')) {
        return docSnapshot.data()!['username'];
      }
    } catch (e) {
      print("Error getting seller's username: $e");
    }
    return null; // Return null if username not found or error occurred
  }


  Future<String> _uploadImage(File image, String path) async {
    FirebaseStorage storage = FirebaseStorage.instance;
    try {
      final ref = storage.ref().child(path);
      await ref.putFile(image);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      return Future.error('Error uploading image');
    }
  }

  Future<File?> _compressImage(File file, String targetPath) async {
    try {
      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 88,
      );

      // Assuming result is now an XFile, convert it to a File
      if (result != null) {
        // Create a File from the XFile path
        return File(result.path);
      } else {
        print("Compression returned null.");
        return null;
      }
    } catch (e) {
      print("Error compressing image: $e");
      return null;
    }
  }

  Future<void> _uploadItem() async {
    if (_imageFiles!.length > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You can only upload up to 5 images.')));
      return;
    }
    if (_descriptionController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill in all fields.')));
      return;
    }
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user logged in.')));
      setState(() {
        _isLoading = false;
      });
      return;
    }

    List<String> imageUrls = [];
    for (var imageFile in _imageFiles!) {
      final dir = await getTemporaryDirectory();
      final targetPath = dir.absolute.path + "/temp.jpg";
      File? compressedImage = await _compressImage(File(imageFile.path), targetPath);
      if(compressedImage != null){
        String imageUrl = await _uploadImage(compressedImage, 'items/${user.uid}/${imageFile.name}');
        imageUrls.add(imageUrl);
      }
    }

    // Convert and validate the price input
    try {
      double priceInput = double.parse(_priceController.text);
      int priceCents = (priceInput * 100).round(); // Convert to cents and round
      String priceString = priceCents.toString(); // Convert to string

      // Generate a new document reference with an auto-generated ID in the 'items' collection
      DocumentReference newItemRef = FirebaseFirestore.instance.collection('items').doc();

// Use the same document ID to create a document in both 'items' and 'itemHistory' collections
      String documentId = newItemRef.id; // This is your consistent document ID for both collections

      final Map<String, dynamic> itemData = {
        'userId': user.email,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'price': priceString, // Use the converted price string
        'images': imageUrls,
        'timestamp': FieldValue.serverTimestamp(),
        'userName': await getSellersUsername(user.email!),
        'amount': int.tryParse(_amountController.text),
        'category': _selectedCategory,
        'buyer': '',
      };

// Now, set the document with the same ID in 'items' collection
      await newItemRef.set(itemData);

// Also, set a document with the same ID in 'itemHistory' collection
      await FirebaseFirestore.instance.collection('itemHistory').doc(documentId).set(itemData);

      addItemToSellerItems(currentEmail, newItemRef.id);
      widget.onItemUploaded();

      setState(() {
        _isLoading = false;
      });


      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid price format. Please enter a value like x.xx')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> addItemToSellerItems(String sellerEmail, String itemId) async {
    final DocumentReference sellerRef = FirebaseFirestore.instance.collection('Users').doc(sellerEmail);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(sellerRef);

      if (!snapshot.exists) {
        throw Exception("Seller does not exist!");
      }

      // Add the item ID to the seller's userItems list if it's not already present
      transaction.update(sellerRef, {
        'userItems': FieldValue.arrayUnion([itemId])
      });
    }).catchError((error) {
      print("Failed to add item to seller's soldItems and userItems: $error");
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Item'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 30,),
            ElevatedButton(
              onPressed: _pickImages,
              child: Text('Select Images'),
            ),
            SizedBox(height: 10),
            Wrap(
              children: _imageFiles!.map((file) => Image.file(File(file.path), width: 270, height: 270)).toList(),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                controller: _titleController,
                decoration: InputDecoration(hintText: 'Title (Max 50 chars)'),
                maxLength: 50,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                controller: _descriptionController,
                decoration: InputDecoration(hintText: 'Description (Max 200 chars)'),
                maxLength: 200,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                controller: _priceController,
                decoration: InputDecoration(hintText: 'Price (e.g., 10.00)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [PriceInputFormatter()],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                controller: _amountController,
                decoration: InputDecoration(hintText: 'Enter of items being sold'),
                keyboardType:  TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly, // Allows only digits
                ],
              ),
            ),
            DropdownButton<String>(
              value: _selectedCategory,
              hint: Text("Select a category"),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
              items: categories.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            ElevatedButton(
              onPressed: _uploadItem,
              child: Text('Upload Item'),
            ),
          ],
        ),
      ),
    );
  }
}