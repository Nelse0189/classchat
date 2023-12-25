import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/physics.dart';

class RegisterClasses extends StatefulWidget {
  const RegisterClasses({Key? key}) : super(key: key);

  @override
  State<RegisterClasses> createState() => _RegisterClasses();
}

class _RegisterClasses extends State<RegisterClasses> {
  final currentUser = FirebaseAuth.instance.currentUser!; // Replace with actual UID
  String? selectedClassId;
  bool isSubcategoriesExpanded = false;
  List<Widget> subcategoryButtons = [];


  @override
  Widget build(BuildContext context) {
    print(currentUser.toString());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classes'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser.email) // Replace with current user's UID
            .collection('classes')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return Column(
              children: [
                // DropdownButton for selecting the class
                DropdownButton<String>(
                  value: selectedClassId,
                  onChanged: (newClassId) async {
                    setState(() {
                      selectedClassId = newClassId;
                      isSubcategoriesExpanded = true;
                    });

                    // Fetch subcategories (assuming they're within the selected class document)
                    final subcategoriesSnapshot = await FirebaseFirestore.instance
                        .collection('Users')
                        .doc(currentUser.toString())
                        .collection('classes')
                        .doc(newClassId)
                        .collection('subcategories') // Assuming subcategories are in a nested subcollection
                        .get();

                    subcategoryButtons = subcategoriesSnapshot.docs
                        .map((subcategory) => TextButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('Users')
                            .doc(currentUser.toString())
                            .collection('classes')
                            .doc(newClassId)
                            .collection('subcategories')
                            .doc(subcategory.id)
                            .update({'isSelected': !subcategory['isSelected']});
                      },
                      child: Text(subcategory['name']),
                    ))
                        .toList();
                  },
                  items: snapshot.data!.docs.map((classDoc) {
                    return DropdownMenuItem<String>(
                      value: classDoc.id,
                      child: Text(classDoc.id), // Use ID as text for clarity
                    );
                  }).toList(),
                ),

                // Expanded list of subcategory buttons (conditionally displayed)
                if (isSubcategoriesExpanded)
                  Expanded(
                    child: ListView(
                      children: subcategoryButtons,
                    ),
                  ),
              ],
            );
          }
        },
      ),
    );
  }
}
