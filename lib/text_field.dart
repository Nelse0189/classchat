import 'package:flutter/material.dart';
import 'package:classchat/auth/constants.dart';


class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLength: 200,
      style: TextStyle(color: Colors.black, fontFamily: 'sfPro', fontSize: 15,),
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderSide:BorderSide(color: theme),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide:BorderSide(color: theme),
        ),
        fillColor: theme,
        filled: true,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.black, fontFamily: 'sfPro', fontSize: 15,),
      ),
    );
  }
}
