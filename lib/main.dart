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
          primaryColor: Color.fromRGBO(149, 213, 178, 1),
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
  bool ready = false;
  Map<String, double> data;

  @override
  void initState(){
    super.initState();

    data = new Map<String , double>();
    _read("todayDate").then((val) {setState(() {data["todayDate"] = val;});});
    _read("todaySpent").then((val) {setState(() {data["todaySpent"] = val;});});
    _read("dailyLimit").then((val) {setState(() {data["dailyLimit"] = val;});});
    _read("monthlySaved").then((val) {setState(() {data["monthlySaved"] = val;});});
    _read("monthlyResetDate").then((val) {setState(() {data["monthlyResetDate"] = val;});});
  }

  void checkNewDay(){
    var now = DateTime.now().toLocal();
    double today = double.parse(now.year.toString() + now.month.toString() + now.day.toString());
    if(data["monthlyResetDate"] == 0) {
      data["monthlyResetDate"] = now.month.toDouble();
    }

    // New Day
    if(data["todayDate"] == 0 || data["todayDate"] != today){
      data["monthlySaved"] += data["dailyLimit"] - data["todaySpent"];
      data["todayDate"] = today;
      data["todaySpent"] = 0;
    }
    ready = true;
    setState((){});

    _save("todayDate", data["todayDate"]);
    _save("monthlySaved", data["monthlySaved"]);
    _save("todaySpent", data["todaySpent"]);
    _save("monthlyResetDate", data["monthlyResetDate"]);
  }

  List<Widget> _children() => [
    SpendMoneyWidget(data: data),
    DisplayWidget(data: data),
  ];

  void _pushSettings(BuildContext context) async {
    // start the SecondScreen and wait for it to finish with a result
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SettingsWidget(data: data),
        ));

    setState(() {
      data = result;
      _save("monthlyResetDate", data["monthlyResetDate"]);
      _save("dailyLimit", data["dailyLimit"]);
    });
  }

  @override
  Widget build(BuildContext context){
    final List<Widget> children = _children();
    if(data == null || data["monthlyResetDate"] == null) {
      return Scaffold(
          backgroundColor: Color.fromRGBO(149, 213, 178, 1),
          body: Text("Loading...")
      );
    }
    if(!ready)
      checkNewDay();
    return Scaffold(
      appBar: AppBar(
        title: Text("Money Tracker"),
        actions: [
          IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {_pushSettings(context);}
          )
        ],
      ),
      body: data != null ? children[_currentIndex] : new Scaffold(),
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped, // new
        currentIndex: _currentIndex, // new
        items: [
          BottomNavigationBarItem(
            icon: new Icon(Icons.attach_money),
            title: new Text('Spend'),
          ),
          BottomNavigationBarItem(
            icon: new Icon(Icons.insert_chart),
            title: new Text('Display'),
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
    double value = prefs.getDouble(key);
    if(value == null){return 0.0;}
    return value;
  }

  _save(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble(key, value);
  }
}

