import 'package:classchat/main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  List<String> registeredClasses= [];
  Color color = Colors.blue.shade700;

  @override
  initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser.email)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        setState(() {
          registeredClasses = documentSnapshot['Registered Classes'].cast<String>();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print(currentUser.toString());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classes'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: Column(
          children: [
            Flexible(
              flex: 1,
              child: SizedBox(
                height: 70,
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
                          "Select Classes",
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                        iconSize: 30.0,
                        itemHeight: 60.0,
                        menuMaxHeight: 500.0,
                        borderRadius: BorderRadius.circular(20.0),
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
            ),
            Flexible(
              flex: 8,
              child: Expanded(
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
                        Color buttonColor = registeredClasses.contains(snap['name'].toString()) ? Colors.grey.shade500 : Colors.blue;
                        subcategoryButtons.add(
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                isSubcategoriesExpanded = true;
                              });
                              if(registeredClasses.contains(snap['name'].toString())) {
                                // Remove from registeredClasses
                                registeredClasses.remove(snap['name'].toString());
                              } else {
                                // Add to registeredClasses
                                registeredClasses.add(snap['name'].toString());
                              }
                              print (registeredClasses);
                            },
                            child: Text(
                              snap['name'],
                              style: const TextStyle(color: Colors.white),
                            ),
                              //how do i style the buttons individually?
                            style: ElevatedButton.styleFrom(primary: buttonColor),),
                        );
                      }
                      return GridView.count(
                        crossAxisCount: 3,
                        children: subcategoryButtons,
                      );
                    }
                  },
                ),
              ),
            ),

            Flexible(
              flex: 1,
              child: ElevatedButton(

                onPressed: () {
                  FirebaseFirestore.instance
                      .collection('Users')
                      .doc(currentUser.email)
                      .update({
                    'classRegistered': true,
                  });
                  FirebaseFirestore.instance
                      .collection('Users')
                      .doc(currentUser.email)
                      .update({'Registered Classes': registeredClasses});
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyHomePage()),
                  );
                },
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}





