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
  final _HomeState myHomeState = new _HomeState();

  @override
  State createState() => myHomeState;

  void checkNewDay(){
    myHomeState.checkNewDay();
  }
}

class _HomeState extends State<HomeWidget>{
  final pageController = PageController(initialPage: 0);
  int _currentIndex = 0;
  bool ready = false;
  bool patched = false;
  bool loaded = false;

  Map<String, String> stringData;
  Map<String, double> data;
  List<Entry> todaySpending;

  @override
  void initState(){
    super.initState();

    SystemChannels.lifecycle.setMessageHandler((msg){
      if(msg==AppLifecycleState.resumed.toString()) {
        setState(() { checkNewDay();});
      }
      return null;
    });

    // Create Map for the session and load the data from Shared Preference.
    data = new Map<String , double>();
    data["todaySpent"] = 0.0;
    data["SpendValue"] = 0;
    stringData = new Map<String, String>();
    stringData["SpendContent"] = "";

    loadValues();
  }

  loadValues(){
    // System Values
    _readSP("dailyLimit").then((val) {setState(() {data["dailyLimit"] = val;});});
    _readSP("totalSaved").then((val) {setState(() {data["totalSaved"] = val;});});
    _readSP("todayDate").then((todayDate) {setState(() {
      data["todayDate"] = todayDate;
      // Query Today Spendings from DB
      _queryDBDay(todayDate.toInt().toString()).then((entries){
        todaySpending = entries;
        for(Entry i in entries){
          data["todaySpent"] += i.amount;
        }
        setState(() { loaded = true; }
        );
      });
    });});

    // UI Parameters
    _readSP("showSave").then((val) {setState(() {data["showSave"] = val;});});
    _readSP("historyMode").then((val) {setState(() {data["historyMode"] = val;});});
    _readSP("version").then((val) {setState(() {data["version"] = val;});});
  }

  // This will run on startup to check if a new day has past.
  void checkNewDay(){
    // Date depends on local
    DateTime now = DateTime.now().toLocal();
    double today = double.parse(getTodayString());

    // If its a new day, accumulate the savings into monthly saving and reset daily
    if(data["todayDate"] != today){
      //Get 'yesterday' spending

     // Accumulate how much was saved yesterday
      data["totalSaved"] += (data["dailyLimit"] + data["todaySpent"]);

      setState(() {});

      // If this app hasn't been opened for a few days, gotta add the missing amounts
      DateTime startOfDay = new DateTime(now.year, now.month, now.day);
      DateTime prev = new DateTime((data["todayDate"]~/10000),
          ((data["todayDate"]%10000)~/100), (data["todayDate"]%100).toInt());

      if(startOfDay.difference(prev).inDays > 1){
        data["totalSaved"] += (startOfDay.difference(prev).inDays - 1) * data["dailyLimit"];
      }

      // New Date and reset
      data["todayDate"] = today;
      data["todaySpent"] = 0;

      _saveSP("todayDate", data["todayDate"]);
      _saveSP("totalSaved", data["totalSaved"]);
      setState((){});
    }
  }

  patch(){

    setState(() {patched = true;});
  }

  // Two Main Screens for the app
  List<Widget> _children() => [
    SpendMoneyWidget(data: data, stringData: stringData),
    DisplayWidget(data: data),
    SpendingHistoryWidget(data: data)
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
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context){
    final List<Widget> children = _children();

    // Minimum Splash Screen
    if(!ready) {
      new Timer(new Duration(milliseconds: 500), () {
        ready = true;
        setState(() {});
      });
    }
    if(loaded){
      patch();
    }
    // While Data is loading, show empty screen
    if(!loaded || !ready || !patched) {
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
  _saveSP(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble(key, value);
  }

  String getTodayString(){
    DateTime dt = DateTime.now().toLocal();
    return DateFormat('yyyyMMdd').format(dt);
  }

  Future<List<Entry>> _queryDBDay(String day) async {
    DatabaseHelper helper = DatabaseHelper.instance;
    return await helper.queryDay(day);
  }
}

