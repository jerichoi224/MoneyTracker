import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_tracker/HomeWidget.dart';
import 'package:money_tracker/SplashWidget.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget{
  Map<String, double> data;

  @override
  Widget build(BuildContext context) {
    data = new Map<String, double>();
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Money Tracker',
        theme: ThemeData(
          primaryColor: Color.fromRGBO(149, 213, 178, 1),
        ),
        home: MainApp(data: data),
        routes: <String, WidgetBuilder>{
          '/home': (BuildContext context) => new HomeWidget(data: data),
          '/splash': (BuildContext context) => new SplashWidget(data: data),
        }
      );
  }
}

class MainApp extends StatefulWidget {
  final Map<String, double> data;
  MainApp({Key key, this.data}) : super(key: key);

  @override
  State createState() => _MainState();
}

class _MainState extends State<MainApp> {

  @override
  void initState() {
    super.initState();
//    widget.data = new Map<String, double>();
  }

  Future checkFirstSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool _seen = (prefs.getBool('seen') ?? false);

    if (_seen) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil('/splash', (Route<dynamic> route) => false);
    }
  }

  Widget build(BuildContext context){
    new Timer(new Duration(milliseconds: 200), () {
      checkFirstSeen();
    });
    return Scaffold(
        body: new Container()
    );
  }
}
