import 'main.dart';
import 'package:flutter/material.dart';


class Splash extends StatefulWidget {
  const Splash({Key? key}) : super (key: key);

  @override
  _SplashState createState() => _SplashState();
}
class _SplashState extends State<Splash>{
  @override
  void initState() {
    super.initState();
    //_navigatetohome();
  }


  _navigatetohome() async{
    await Future.delayed(Duration(milliseconds: 1500),(){});
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => MyHomePage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height:100,width: 100,color: Colors.redAccent,
            ),
            Container(
              child: Text('Class Chat ', style: TextStyle(
                fontSize: 24.0,
                fontFamily: 'Roboto',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

