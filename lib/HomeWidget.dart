import 'package:flutter/material.dart';
import 'package:money_tracker/SpendMoneyWidget.dart';
import 'package:money_tracker/database_helpers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'DisplayWidget.dart';
import 'SpendMoneyWidget.dart';
import 'TodaySpendingWidget.dart';
import 'SettingsWidget.dart';
import 'dart:async';

class HomeWidget extends StatefulWidget {
  final Map<String, double> data;
  HomeWidget({Key key, this.data}) : super(key: key);

  @override
  State createState() => _HomeState();
}


class _HomeState extends State<HomeWidget>{
  final pagecontroller = PageController(initialPage: 0);
  int _currentIndex = 0;
  bool ready = false;

  Map<String, String> StringData;
  Map<String, double> data;
  List<Entry> todaySpendings;

  @override
  void initState(){
    super.initState();

    // Create Map for the session and load the data from Shared Preference.
    data = new Map<String , double>();
    StringData = new Map<String, String>();
    _readSP("todayDate").then((val) {setState(() {data["todayDate"] = val;});});
    _readSP("todaySpent").then((val) {setState(() {data["todaySpent"] = val;});});
    _readSP("dailyLimit").then((val) {setState(() {data["dailyLimit"] = val;});});
    _readSP("monthlySaved").then((val) {setState(() {data["monthlySaved"] = val;});});
    _readSP("monthlyResetDate").then((val) {setState(() {data["monthlyResetDate"] = val;});});

    // These value are only available while the app is running.
    data["SpendValue"] = 0;
    StringData["SpendContent"] = "";
    _queryDB().then((val){setState(() {todaySpendings = val;});});
  }

  // This will run on startup to check if a new day has past.
  void checkNewDay(){
    // Date depends on local
    var now = DateTime.now().toLocal();

    //Save current day as double with yyyyMMdd
    double today = double.parse(now.year.toString() + now.month.toString() + now.day.toString());

    // If this is the first time the app runs, monthly reset day is set to today
    // TODO: Make user able to choose the date first time app is installed.
    if(data["monthlyResetDate"] == 0) {
      data["monthlyResetDate"] = now.day.toDouble();
      _saveSP("monthlyResetDate", data);
    }

    // If its a new day, accumulate the savings into monthly saving and reset daily
    if(data["todayDate"] == 0 || data["todayDate"] != today){
      data["monthlySaved"] += data["dailyLimit"] - data["todaySpent"];
      data["todayDate"] = today;
      data["todaySpent"] = 0;

      // Check if today is the monthly reset day
      if(data["monthlyResetDate"].toInt() == now.day){
        data["monthlySaved"] = 0;
      }
      // Save Values
      _saveSP("todayDate", data);
      _saveSP("monthlySaved", data);
      _saveSP("todaySpent", data);
    }

    setState((){});
  }

  // Two Main Screens for the app
  List<Widget> _children() => [
    SpendMoneyWidget(data: data, todaySpendings: todaySpendings, StringData: StringData),
    DisplayWidget(data: data),
    TodaySpendingWidget(data: data, todaySpendings: todaySpendings,)
  ];

  // Navigate to Settings screen
  void _pushSettings(BuildContext context) async {
    // start the SecondScreen and wait for it to finish with a result
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SettingsWidget(data: data),
        ));

    // Update any values that have changed.
    setState(() {
      data = result;
    });
  }

  changePage(int index){
    if(index == 2) {
      _queryDB().then((val) {
        setState(() {
          todaySpendings = val;
        });
      });
    }
    setState(() {
      _currentIndex = index;
    });
  }

  checkLoaded(){
    return data == null || data["todaySpent"] == null || todaySpendings == null;
  }

  @override
  Widget build(BuildContext context){
    final List<Widget> children = _children();
    new Timer(new Duration(milliseconds: 300), () {
      ready = true;
      setState(() {});
    });

    // While Data is loading, show empty screen
    if(checkLoaded() || !ready) {
      return Scaffold(
          body: new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(15),
                  child: Center(
                      child: Image(
                        image: AssetImage('assets/my_icon.png'),
                        width: 150,
                      )),
                ),
              ])
      );
    }

    // Once Data loads, check if its a new day since last run.
    checkNewDay();

      // App Loads
    return Scaffold(
      appBar: AppBar(
        title: Text("Money Tracker"),
        actions: [
          IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                _pushSettings(context);
              }
          )
        ],
      ),
      body: PageView(
          onPageChanged: (index) {
            FocusScope.of(context).unfocus();
            changePage(index);
          },
          controller: pagecontroller,
          children: children
      ),
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
          BottomNavigationBarItem(
            icon: new Icon(Icons.calendar_today),
            title: new Text('Today'),
          ),
        ],
      ),
    );
  }

  void onTabTapped(int index) {
    if(index == 2) {
      _queryDB().then((val) {
        setState(() {
          todaySpendings = val;
        });
      });
    }
    setState(() {
      _currentIndex = index;
      pagecontroller.animateToPage(index, duration: Duration(milliseconds: 500), curve: Curves.ease);
    });
  }

  // Reading from Shared Preferences
  Future<double> _readSP(String key) async {
    final prefs = await SharedPreferences.getInstance();
    double value = prefs.getDouble(key);
    if(value == null){return 0.0;}
    return value;
  }

  // Saving to Shared Preferences
  _saveSP(String key, Map<String, double> data) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble(key, data[key]);
  }

  Future<List<Entry>> _queryDB() async {
    DatabaseHelper helper = DatabaseHelper.instance;
    DateTime dt = DateTime.now().toLocal();
    String day = dt.year.toString() + dt.month.toString() + dt.day.toString();
    return await helper.queryDay(day);
  }
}

