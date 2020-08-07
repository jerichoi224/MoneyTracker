import 'package:flutter/material.dart';
import 'package:money_tracker/SpendMoneyWidget.dart';
import 'package:money_tracker/database_helpers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'DisplayWidget.dart';
import 'SpendMoneyWidget.dart';
import 'SpendingHistory.dart';
import 'SettingsWidget.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

class HomeWidget extends StatefulWidget {
  final BuildContext parentCtx;

  HomeWidget({Key key, this.parentCtx});

  @override
  State createState() => _HomeState();

}

class _HomeState extends State<HomeWidget>{
  final pageController = PageController(initialPage: 0);
  int _currentIndex = 0, today;
  bool ready = false;
  bool patched = false;

  Map<String, String> stringData;
  Map<String, num> numData;
  List<SpendingEntry> todaySpending;
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
    numData = new Map<String , num>();
    numData["todaySpent"] = 0;
    numData["SpendValue"] = 0;

    stringData = new Map<String, String>();
    stringData["SpendContent"] = "";

    loadValues();
  }

  loadValues(){
    // System Values
    _readSP("currency").then((val) {setState(() {stringData["currency"] = val == null ? "USD" : val;});});
    _readSP("dailyLimit").then((val) {setState(() {numData["dailyLimit"] = val == null ? 0 : val;});});
    _readSP("totalSaved").then((val) {setState(() {numData["totalSaved"] = val == null ? 0 : val;});});
    _readSP("todayDate").then((todayDate) {setState(() {
      numData["todayDate"] = todayDate;
      // Query Today Spendings from DB
      _queryDBDay(todayDate).then((entries){
        todaySpending = entries;
        for(SpendingEntry i in entries){
          numData["todaySpent"] += i.amount;
        }
        setState(() {}
        );
      });
    });});

    numData["spendAmount"] = 0;

    _queryAllSubscriptionsDB().then((entries){
      setState(() {
        subscriptions = entries;
      });
    });

    // UI Parameters
    _readSP("showSave").then((val) {setState(() {numData["showSave"] = val;});});
    _readSP("historyMode").then((val) {setState(() {numData["historyMode"] = val == null ? 0 : val;});});
    _readSP("version").then((val) {setState(() {numData["version"] = val;});});
  }

  void addSubscriptionEntry(SubscriptionEntry i, DateTime dt){

    SpendingEntry subscriptionEntry = new SpendingEntry();
    subscriptionEntry.day = dt.millisecondsSinceEpoch;
    subscriptionEntry.timestamp = DateTime(dt.year, dt.month, dt.day).millisecondsSinceEpoch;
    subscriptionEntry.amount = i.amount * -1;
    subscriptionEntry.content = i.content + " (Subscription)";

    if(dt.millisecondsSinceEpoch == today){
      numData["todaySpent"] -= i.amount;
    }else{
      numData["totalSaved"] -= i.amount;
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
    today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

    // If its a new day, accumulate the savings into monthly saving and reset daily
    if(numData["todayDate"] != today){
      DateTime prevDate = DateTime.fromMillisecondsSinceEpoch(numData["todayDate"]);

      //Get 'yesterday' spending
      // Accumulate how much was saved yesterday
      numData["totalSaved"] += (numData["dailyLimit"] + numData["todaySpent"]);
      numData["todaySpent"] = 0;

      for(DateTime dt in calculateDaysInterval(prevDate, DateTime.fromMillisecondsSinceEpoch(today))) {
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
        if(dt.millisecondsSinceEpoch != today){
          numData["totalSaved"] += numData["dailyLimit"];
        }
      }

      // New Date and reset
      numData["todayDate"] = today;

      _saveSP("todayDate", numData["todayDate"]);
      _saveSP("totalSaved", numData["totalSaved"]);
      setState((){});
    }
  }

  patch(){
    setState(() {patched = true;});
  }

  List<Widget> _children() => [
    SpendMoneyWidget(numData: numData, stringData: stringData),
    DisplayWidget(numData: numData, subscriptions: subscriptions, stringData: stringData),
    SpendingHistoryWidget(numData: numData, stringData: stringData,)
  ];

  // Navigate to Settings screen
  void _pushSettings(BuildContext context) async {
    // start the SecondScreen and wait for it to finish with a result
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SettingsWidget(numData: numData, subscriptions: subscriptions, stringData: stringData,),
        ));

    setState(() {});
    if(result){
      todaySpending.clear();
      numData["totalSaved"] = 0;
      _saveSP("totalSaved", numData["totalSaved"]);
      Phoenix.rebirth(widget.parentCtx);
    }
  }

  changePage(int index){
    setState(() {
      _currentIndex = index;
    });
  }

  isLoaded(){
    return numData != null && subscriptions != null && todaySpending != null;
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
  Future<dynamic> _readSP(String key) async {
    final prefs = await SharedPreferences.getInstance();
    dynamic value = prefs.get(key);
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

  Future<List<SpendingEntry>> _queryDBDay(num day) async {
    DatabaseHelper helper = DatabaseHelper.instance;
    return await helper.queryDay(day);
  }

  Future<List<SubscriptionEntry>> _queryAllSubscriptionsDB() async {
    DatabaseHelper helper = DatabaseHelper.instance;
    return await helper.queryAllSubscriptions();
  }

  _saveDB(SpendingEntry entry) async {
    DatabaseHelper helper = DatabaseHelper.instance;
    await helper.insertSpending(entry);
  }
}

