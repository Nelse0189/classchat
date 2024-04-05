import 'package:flutter/material.dart';
import 'auth/constants.dart';

class MyTextBox2 extends StatelessWidget {
  final String text2;
  final String sectionName2;
  const MyTextBox2({
    super.key,
    required this.text2,
    required this.sectionName2,
  });

  @override

  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: theme,
          borderRadius: BorderRadius.circular(8)
      ),
      padding: const EdgeInsets.only(left:15, bottom: 15, top: 15),
      margin: const EdgeInsets.only(left: 20, right: 20, top: 20),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // section name
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  sectionName2,
                  style: TextStyle(color: Colors.white, fontFamily: 'sfPro', fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 5,),
            // text
            Text(text2, style: TextStyle(color: Colors.white, fontFamily: 'sfPro', fontSize: 15,),),
          ]
      ),

    );
  }
}