import 'package:classchat/main.dart';
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
  final currentUser = FirebaseAuth.instance
      .currentUser!; // Replace with actual UID
  String? selectedClassId = 'Select Classes';
  bool isSubcategoriesExpanded = false;
  List<Widget> subcategoryButtons = [];
  List<DropdownMenuItem> classList = [];
  int docCount = 0;


  @override
  Widget build(BuildContext context) {
    print(currentUser.toString());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classes'),
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection("Classes")
                    .orderBy("Name")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else {
                    List<DropdownMenuItem> classList = [];
                    for (int i = 0; i < snapshot.data!.docs.length; i++) {
                      DocumentSnapshot snap = snapshot.data!.docs[i];
                      classList.add(DropdownMenuItem(
                        child: Text(
                          snap['Name'],
                          style: const TextStyle(color: Colors.black),
                        ),
                        value: "${snap.id}",
                      ));
                    }
                    return DropdownButton(
                      hint: const Text(
                        "Select Class",
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        color: Colors.black,
                      ),
                      value: selectedClassId,
                      items: classList,
                      onChanged: (value) {
                        setState(() {
                          selectedClassId = value.toString();
                        });
                      },
                    );
                  }
                },
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection("Classes")
                    .doc(selectedClassId)
                    .collection("subclasses")
                    .orderBy("name")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else {
                    List<Widget> subcategoryButtons = [];
                    for (int i = 0; i < snapshot.data!.docs.length; i++) {
                      DocumentSnapshot snap = snapshot.data!.docs[i];
                      subcategoryButtons.add(
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isSubcategoriesExpanded = true;
                            });
                          },
                          child: Text(
                            snap['name'],
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      );
                    }
                    return GridView.count(
                      crossAxisCount: 2,
                      children: subcategoryButtons,
                    );
                  }
                },
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection("Classes")
                    .doc(selectedClassId)
                    .collection("Subclasses")
                    .orderBy("name")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else {
                    List<Widget> subcategoryButtons = [];
                    for (int i = 0; i < snapshot.data!.docs.length; i++) {
                      DocumentSnapshot snap = snapshot.data!.docs[i];
                      subcategoryButtons.add(
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isSubcategoriesExpanded = true;
                            });
                          },
                          child: Text(
                            snap['name'],
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      );
                    }
                    return GridView.count(
                      crossAxisCount: 2,
                      children: subcategoryButtons,
                    );
                  }
                },

              ),
            ),

            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('Users')
                    .doc(currentUser.email)
                    .update({
                  'classRegistered': true,
                  'name': currentUser.email!.split('@')[0],
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyHomePage(title: 'ClassChat',)),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}





