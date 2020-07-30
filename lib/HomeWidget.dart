import 'package:flutter/material.dart';
import 'package:money_tracker/SpendMoneyWidget.dart';
import 'package:money_tracker/database_helpers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'DisplayWidget.dart';
import 'SpendMoneyWidget.dart';
import 'SpendingHistory.dart';
import 'SettingsWidget.dart';
import "package:intl/intl.dart";
import 'dart:async';
import 'package:flutter/services.dart';

class HomeWidget extends StatefulWidget {
  @override
  State createState() => _HomeState();
}

class _HomeState extends State<HomeWidget>{
  final pageController = PageController(initialPage: 0);
  int _currentIndex = 0;
  bool ready = false;

  Map<String, String> stringData;
  Map<String, double> data;
  List<Entry> todaySpending;

  @override
  void initState(){
    super.initState();

    SystemChannels.lifecycle.setMessageHandler((msg){
      if(msg==AppLifecycleState.resumed.toString())
        setState((){});
      return null;
    });

    // Create Map for the session and load the data from Shared Preference.
    data = new Map<String , double>();
    stringData = new Map<String, String>();
    _readSP("todayDate").then((val) {setState(() {
      data["todayDate"] = val;
      // Query Today Spendings from DB
      _queryDayDB(val.toInt().toString()).then((entries){
          setState(() {
            todaySpending = entries;
          }
          );
      });
    });});
    _readSP("dailyLimit").then((val) {setState(() {data["dailyLimit"] = val;});});
    _readSP("monthlySaved").then((val) {setState(() {data["monthlySaved"] = val;});});
    _readSP("monthlyResetDate").then((val) {setState(() {data["monthlyResetDate"] = val;});});
    _readSP("firstDay").then((val) {setState(() {data["firstDay"] = val;});});

    // These value are only available while the app is running.
    data["SpendValue"] = 0;
    stringData["SpendContent"] = "";
  }

  // This will run on startup to check if a new day has past.
  void checkNewDay(){
    // Date depends on local
    DateTime now = DateTime.now().toLocal();
    double today = double.parse(getTodayString());

    // If its a new day, accumulate the savings into monthly saving and reset daily
    if(data["todayDate"] != today){
      //Get 'yesterday' spending
      double todaySpent = 0;
      for(Entry i in todaySpending){
        todaySpent += i.amount;
      }

      // Accumulate how much was saved yesterday
      data["monthlySaved"] += (data["dailyLimit"] - todaySpent);

      // If this app hasn't been opened for a few days, gotta add the missing amounts
      DateTime startOfDay = new DateTime(now.year, now.month, now.day);
      DateTime prev = new DateTime((data["todayDate"]/10000).toInt(),
          ((data["todayDate"]%10000)/100).toInt(), (data["todayDate"]%100).toInt());

      if(startOfDay.difference(prev).inDays > 1){
        data["monthlySaved"] += (startOfDay.difference(prev).inDays - 1) * data["dailyLimit"];
      }

      // New Date and reset
      data["todayDate"] = today;

      // Check if today is the monthly reset day
      if(data["monthlyResetDate"].toInt() == now.day){
        data["monthlySaved"] = 0;
      }
      // Save Values
      _saveSP("todayDate", data);
      _saveSP("monthlySaved", data);
      setState((){});
    }
  }

  // Two Main Screens for the app
  List<Widget> _children() => [
    SpendMoneyWidget(data: data, todaySpendings: todaySpending, StringData: stringData),
    DisplayWidget(data: data, todaySpendings: todaySpending),
    SpendingHistoryWidget(data: data, todaySpendings: todaySpending,)
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
      _queryDayDB(getTodayString()).then((val) {
        setState(() {
          todaySpending = val;
        });
      });
    }
    setState(() {
      _currentIndex = index;
    });
  }

  checkLoaded(){
    return data == null || todaySpending == null;
  }

  @override
  Widget build(BuildContext context){
    final List<Widget> children = _children();
    if(!ready) {
      new Timer(new Duration(milliseconds: 700), () {
        ready = true;
        setState(() {});
      });
    }
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
          controller: pageController,
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
            icon: new Icon(Icons.history),
            title: new Text('History'),
          ),
        ],
      ),
    );
  }

  void onTabTapped(int index) {
    if(index == 2) {
      _queryDayDB(getTodayString()).then((val) {
        setState(() {
          todaySpending = val;
        });
      });
    }
    setState(() {
      _currentIndex = index;
      pageController.animateToPage(index, duration: Duration(milliseconds: 500), curve: Curves.ease);
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

  String getTodayString(){
    DateTime dt = DateTime.now().toLocal();
    return DateFormat('yyyyMMdd').format(dt);
  }

  Future<List<Entry>> _queryDayDB(String day) async {
    DatabaseHelper helper = DatabaseHelper.instance;
    return await helper.queryDay(day);
  }
}

