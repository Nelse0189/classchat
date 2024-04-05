import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:classchat/auth/login_or_register.dart';
import 'package:classchat/auth/login_page.dart';
import 'package:classchat/auth/register_page.dart';
import 'package:flutter/material.dart';
import 'message_page.dart';
import 'search_page.dart';
import 'auth/auth.dart';
import 'text_box.dart';
import 'profile_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';
import 'class_page.dart';
import 'auth/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'marketplace.dart';
bool start = true;
Future<void> main() async {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.blue,
  ));
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = "pk_live_51OoXzAL1HYVwyPR6Sq0Jq1vJxO9oT1ItICvYKqNd0Wz26a3jfUiQfAbb7ePB89aqSFBud6vHPWpX6bXmyS2c2CPF00gwO0rw9T";
  Stripe.merchantIdentifier = 'merchant.vend';
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('test');
  runApp(const MyApp());
}

Future<bool> checkClassRegistration() async {
  try {
    var email = FirebaseAuth.instance.currentUser?.email;
    if (email != null) {
      var snapshot = await FirebaseFirestore.instance.collection('Users').doc(email).get();
      return snapshot.data()?['classRegistered'] ?? false;
    }
    return false;
  } catch (e) {
    print("Error fetching data: $e");
    return false;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        ),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ClassChat',
        theme: ThemeData(
          // This is the theme of your applicaftion.
          //
          // TRY THIS: Try running your application with "flutter run". You'll see
          // the application has a purple toolbar. Then, without quitting the app,
          // try changing the seedColor in the colorScheme below to Colors.green
          // and then invoke "hot reload" (save your changes or press the "hot
          // reload" button in a Flutter-supported IDE, or press "r" if you used
          // the command line to start the app).
          //
          // Notice that the counter didn't reset back to zero; the application
          // state is not lost during the reload. To reset the state, use hot
          // restart instead.
          //
          // This works for code too, not just values: Most code changes can be
          // tested with just a hot reload.

          colorScheme:
              ColorScheme.fromSeed(seedColor: theme,brightness: Brightness.light),
          useMaterial3: false,
        ),
        home: AnimatedSplashScreen(
          splash: Image.asset('images/owl2.png'),
          splashIconSize: 200,
          duration: 1500,
          splashTransition: SplashTransition.fadeTransition,
          backgroundColor: Colors.blue,
          nextScreen: AuthPage(),
        ),),);
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title = 'Skubble';

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  late List<Widget> _pages;
  late List<BottomNavigationBarItem> _navBarItems;

  @override
  void initState() {
    super.initState();
    _setupNavigationItems();
  }

  void _setupNavigationItems() {
    var user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // User is not authenticated
      _pages = [
        MarketPlace(),
        ClassPage(),
      ];
      _navBarItems = [
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag),
          label: 'Marketplace',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.class_),
          label: 'Class',
        ),
      ];
    } else {
      // User is authenticated
      _pages = [
        ClassPage(),
        MarketPlace(),
        SearchPage(),
        ProfilePage(),
      ];
      _navBarItems = [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Class',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag),
          label: 'Marketplace',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: theme3,
        unselectedItemColor: theme3,
        backgroundColor: navBarColor,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _navBarItems,
      ),
    );
  }
}

