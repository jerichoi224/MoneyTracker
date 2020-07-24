import 'package:flutter/material.dart';
import 'package:money_tracker/SpendMoneyWidget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'DisplayWidget.dart';
import 'SpendMoneyWidget.dart';
import 'SettingsWidget.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Money Tracker',
        theme: ThemeData(
          primaryColor: Colors.lightGreen,
        ),
        home: MainApp(),
        routes: <String, WidgetBuilder>{
          '/settings': (BuildContext context) => new SettingsWidget(),
        }
      );
  }
}

class MainApp extends StatefulWidget {
  @override
  State createState() => _MainState();
}

class _MainState extends State<MainApp>{
  int _currentIndex = 0;
  Map<String, double> data;

  List<Widget> _children() => [
    DisplayWidget(data: data),
    SpendMoneyWidget(data: data),
  ];

  _MainState(){
    data = new Map<String , double>();
    _read("todayDate").then((val) => setState(() {data["todayDate"] = val;}));
    _read("todaySpent").then((val) => setState(() {data["todaySpent"] = val;}));
    _read("dailyLimit").then((val) => setState(() {data["dailyLimit"] = val;}));
    _read("monthlySpent").then((val) => setState(() {data["monthlySpent"] = val;}));
    _read("monthlyLimit").then((val) => setState(() {data["monthlyLimit"] = val;}));
    _read("monthlyResetDate").then((val) => setState(() {data["monthlyResetDate"] = val;}));

    var now = DateTime.now().toLocal();
    double today = double.parse(now.year.toString() + now.month.toString() + now.day.toString());

    if(data["todayDate"] == 0 || data["todayDate"] != today){
      data["todayDate"] = today;
      data["todaySpent"] = 0;
    }
  }

  void _pushSettings(){
    Navigator.of(context).push(new MaterialPageRoute(builder:
        (BuildContext context) => new SettingsWidget()));
  }

  @override
  Widget build(BuildContext context){
    final List<Widget> children = _children();

    return Scaffold(
      appBar: AppBar(
        title: Text("Money Tracker"),
        actions: [
          IconButton(
              icon: Icon(Icons.settings),
              onPressed: () => Navigator.of(context).pushNamed('/settings')
          )
        ],
      ),
      body: children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped, // new
        currentIndex: _currentIndex, // new
        items: [
          BottomNavigationBarItem(
            icon: new Icon(Icons.insert_chart),
            title: new Text('Display'),
          ),
          BottomNavigationBarItem(
            icon: new Icon(Icons.attach_money),
            title: new Text('Spend'),
          ),
        ],
      ),
    );
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<double> _read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    double value = prefs.getDouble(key) ?? 0;
    return value;
  }

  _save(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble(key, value);
  }
}

