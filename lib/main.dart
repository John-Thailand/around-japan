import 'package:around_country/login/login_page.dart';
import 'package:around_country/setting/setting_page.dart';
import 'package:around_country/share/share_page.dart';
import 'package:around_country/signup/signup_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'main_page.dart';
import 'menu/menu_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // ここ大事！
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/signup': (BuildContext context) => SignUpPage(),
        '/login': (BuildContext context) => LoginPage(),
        '/menu': (BuildContext context) => MenuPage(),
        '/share': (BuildContext context) => SharePage(),
        '/setting': (BuildContext context) => SettingPage(),
      },
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainPage(),
    );
  }
}
