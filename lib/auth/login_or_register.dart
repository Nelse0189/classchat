import 'package:flutter/material.dart';

import 'login_page.dart';
import 'register_page.dart';

class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({super.key});

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {

  bool showLoginPage = true;
  //toggle method to toggle between login and register page
  void togglePages(){
    setState(() {
      showLoginPage = !showLoginPage;

    });
  }
  @override
  Widget build(BuildContext context) {
    if(showLoginPage) {
      return LoginPage();
    }
    else{
      return RegisterPage();
    }
  }
}

