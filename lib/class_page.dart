import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './auth/auth.dart';
import 'message_page.dart';
import 'auth/constants.dart';
import 'message_page.dart';
    
class ClassPage extends StatefulWidget {
  const ClassPage({super.key});

  @override
  State<ClassPage> createState() => _ClassPageState();
}

class _ClassPageState extends State<ClassPage> {

  List<String> users = [];
  int userCount = 0;


  @override
  void initState() {
    super.initState();
  }

  void signOut(){
    FirebaseAuth.instance.signOut();
    Navigator.push(context,MaterialPageRoute(builder: (context) => AuthPage(),),);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('ClassChat', style: TextStyle(fontFamily: 'Roboto'),),
          centerTitle: true,
          actions: [
            IconButton(
                onPressed: signOut,
                icon: Icon(Icons.logout)),
          ],
        ),
      drawer: Drawer(
        backgroundColor: Colors.blueGrey.shade900,
          child: Column(
            children: [
              SizedBox(
                height: 50,
              ),
              Container(
                height: 50,
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
                alignment: Alignment.centerLeft,
                color: Colors.grey.shade900,
                child: Row(
                  children: [
                    Text('Direct Messages', style: TextStyle(fontFamily: 'Roboto', color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 20),),
                    SizedBox(width: 10,),
                    IconButton(onPressed: (){}, icon: Icon(Icons.person_3_outlined, color: Colors.amber,))
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance.collection('Users').doc(FirebaseAuth.instance.currentUser!.email).snapshots(),
                  builder:(context,snapshot){
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else {
                      return ListView.builder(
                        itemCount: snapshot.data!['Friends'].length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(snapshot.data!['Friends'][index], style: TextStyle(fontFamily: 'Roboto', color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 15),),
                            onTap: () {
                              selectedUser = snapshot.data!['Friends'][index];
                              Navigator.push(context,MaterialPageRoute(builder: (context) => HomePage(),),);
                            }
                          );
                        },
                      );
                    }
                  }
                )
              )
            ]
          )
      ),
        body: Center(
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder(
                    stream: FirebaseFirestore.instance.collection('Users').doc(FirebaseAuth.instance.currentUser!.email).snapshots(),
                      builder:(context,snapshot){
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else {
                            return ListView.builder(
                              itemCount: snapshot.data!['Registered Classes'].length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(snapshot.data!['Registered Classes'][index], style: TextStyle(fontFamily: 'Roboto', color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 19)),
                                  onTap: () {
                                    currentClass = snapshot.data!['Registered Classes'][index];
                                    print (currentClass);
                                    Navigator.push(context,MaterialPageRoute(builder: (context) => HomePage(),),);
                                  }
                                );
                              },
                            );

                        }
                      }
                ),
              )
            ]
          )
        ),

    );
  }
}
