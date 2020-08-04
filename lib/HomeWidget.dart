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

  Map<String, String> stringData;
  Map<String, double> data;
  List<SingleEntry> todaySpending;
  List<SubscriptionEntry> subscriptions;

  @override
  void initState(){
    super.initState();

    SystemChannels.lifecycle.setMessageHandler((msg){
      if(msg==AppLifecycleState.resumed.toString()) {
        _queryAllSubscriptionsDB().then((entries){
          subscriptions = entries;
          checkNewDay();
          setState(() {});
        });
      }
      return null;
    });

    // Create Map for the session and load the data from Shared Preference.
    data = new Map<String , double>();
    data["todaySpent"] = 0.0;
    data["SpendValue"] = 0;
    stringData = new Map<String, String>();
    stringData["SpendContent"] = "";

    // Reset Values for the subscription
    _saveSP("SubscriptionContentText", null);
    _saveSP("SubscriptionAmountText", null);
    _saveSP("SubscriptionYearlyRenewDate", null);
    _saveSP("SubscriptionMonthlyRenewDay", null);
    _saveSP("cycle", null);

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
        for(SingleEntry i in entries){
          data["todaySpent"] += i.amount;
        }
        setState(() {}
        );
      });
    });});

    _queryAllSubscriptionsDB().then((entries){
      setState(() {
        subscriptions = entries;
      });
    });

    // UI Parameters
    _readSP("showSave").then((val) {setState(() {data["showSave"] = val;});});
    _readSP("historyMode").then((val) {setState(() {data["historyMode"] = val;});});
    _readSP("version").then((val) {setState(() {data["version"] = val;});});
  }

  void addSubscriptionEntry(SubscriptionEntry i, DateTime dt){

    SingleEntry subscriptionEntry = new SingleEntry();
    subscriptionEntry.day = DateFormat('yyyyMMdd').format(dt);
    subscriptionEntry.timestamp = DateTime(dt.year, dt.month, dt.day).millisecondsSinceEpoch;
    subscriptionEntry.amount = i.amount * -1;
    subscriptionEntry.content = i.content + " (Subscription)";

    if(dt.year == DateTime.now().year && dt.month == DateTime.now().month && dt.day == DateTime.now().day){
      data["todaySpent"] -= i.amount;
    }else{
      data["totalSaved"] -= i.amount;
    }
    _saveDB(subscriptionEntry);
  }

  List<DateTime> calculateDaysInterval(DateTime startDate, DateTime endDate) {
    List<DateTime> days = [];
    DateTime tmp = DateTime(startDate.year, startDate.month, startDate.day, 12);
    while(DateTime(tmp.year, tmp.month, tmp.day) != endDate){
      tmp = tmp.add(new Duration(days: 1));
      days.add(DateTime(tmp.year, tmp.month, tmp.day));
    }

    return days;
  }

  // This will run on startup to check if a new day has past.
  void checkNewDay(){
    // Date depends on local
    DateTime now = DateTime.now().toLocal();
    double today = double.parse(getTodayString());

    double prev = data["todayDate"];
    DateTime prevDate = DateTime(prev~/10000, (prev % 10000) ~/100, (prev % 100).toInt());

    // If its a new day, accumulate the savings into monthly saving and reset daily
    if(data["todayDate"] != today){
      //Get 'yesterday' spending
      // Accumulate how much was saved yesterday
      data["totalSaved"] += (data["dailyLimit"] + data["todaySpent"]);
      data["todaySpent"] = 0.0;

      for(DateTime dt in calculateDaysInterval(prevDate, DateTime(now.year, now.month, now.day))) {
        for(SubscriptionEntry i in subscriptions){
          DateTime renew = DateTime.fromMillisecondsSinceEpoch(i.day);
          if (renew.day == dt.day){
            if (i.cycle == 0) {
              addSubscriptionEntry(i, dt);
            } else {
              if (renew.month == dt.month) {
                addSubscriptionEntry(i, dt);
              }
            }
          }
        }
        // If this app hasn't been opened for a few days, gotta add the missing amounts
        if(dt != DateTime(now.year, now.month, now.day)){
          data["totalSaved"] += data["dailyLimit"];
        }
      }

      // New Date and reset
      data["todayDate"] = today;

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
    DisplayWidget(data: data, subscriptions: subscriptions),
    SpendingHistoryWidget(data: data)
  ];

  // Navigate to Settings screen
  void _pushSettings(BuildContext context) async {
    // start the SecondScreen and wait for it to finish with a result
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SettingsWidget(data: data, subscriptions: subscriptions),
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

  isLoaded(){
    return subscriptions != null && todaySpending != null;
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
    if(isLoaded()){
      patch();
    }
    // While Data is loading, show empty screen
    if(!isLoaded() || !ready || !patched) {
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

    if(value is String) {prefs.setString(key, value);}
    else if(value is bool) {prefs.setBool(key, value);}
    else if(value is int) {prefs.setInt(key, value);}
    else if(value is double) {prefs.setDouble(key, value);}
    else {prefs.setStringList(key, value);}
  }

  String getTodayString(){
    DateTime dt = DateTime.now().toLocal();
    return DateFormat('yyyyMMdd').format(dt);
  }

  Future<List<SingleEntry>> _queryDBDay(String day) async {
    DatabaseHelper helper = DatabaseHelper.instance;
    return await helper.queryDay(day);
  }

  Future<List<SubscriptionEntry>> _queryAllSubscriptionsDB() async {
    DatabaseHelper helper = DatabaseHelper.instance;
    return await helper.queryAllSubscriptions();
  }

  _saveDB(SingleEntry entry) async {
    DatabaseHelper helper = DatabaseHelper.instance;
    await helper.insert(entry);
  }
}

