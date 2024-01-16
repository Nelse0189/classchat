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
      style: TextStyle(color: Colors.blueGrey, fontFamily: 'Roboto', fontSize: 15, fontWeight: FontWeight.bold,),
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        enabledBorder: const OutlineInputBorder(
          borderSide:BorderSide(color: Colors.amber),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide:BorderSide(color: Colors.amber),
        ),
        fillColor: Colors.amber,
        filled: true,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.blueGrey, fontFamily: 'Roboto', fontSize: 15, fontWeight: FontWeight.bold,),
      ),
    );
  }
}
