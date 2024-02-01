import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './auth/auth.dart';
import 'message_page.dart';
import 'auth/constants.dart';
    
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
    getUserTheme();
  }

  void signOut(){
    FirebaseAuth.instance.signOut();
    Navigator.push(context,MaterialPageRoute(builder: (context) => AuthPage(),),);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme2,
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          backgroundColor: theme,
          titleTextStyle: TextStyle(fontFamily: 'sfPro', color: Colors.white, fontSize: 20),
          title: Text('Unilo', style: TextStyle(fontFamily: 'SfProBold'),),
          centerTitle: true,
          actions: [
            IconButton(
                onPressed: signOut,
                icon: Icon(Icons.logout), color: Colors.white,),
          ],
        ),
      drawer: Drawer(
        backgroundColor: theme,
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
                    Text('Direct Messages', style: TextStyle(fontFamily: 'sfPro', color: theme, fontSize: 20),),
                    SizedBox(width: 10,),
                    IconButton(onPressed: (){}, icon: Icon(Icons.person_3_outlined, color: theme,))
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
                            title: Text(snapshot.data!['Friends'][index], style: TextStyle(fontFamily: 'sfProSemiBold', color: Colors.white, fontSize: 16),),
                            onTap: () {
                              selectedUser = snapshot.data!['Friends'][index] + '@gmail.com';
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
                                  title: Text(snapshot.data!['Registered Classes'][index], style: TextStyle(fontFamily: 'sfPro', color: theme,  fontSize: 19)),
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
