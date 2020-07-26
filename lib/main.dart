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
  final pagecontroller = PageController(initialPage: 0);
  int _currentIndex = 0;
  bool ready = false;
  Map<String, double> data;

  @override
  void initState(){
    super.initState();

    // Create Map for the session and load the data from Shared Preference.
    data = new Map<String , double>();
    _read("todayDate").then((val) {setState(() {data["todayDate"] = val;});});
    _read("todaySpent").then((val) {setState(() {data["todaySpent"] = val;});});
    _read("dailyLimit").then((val) {setState(() {data["dailyLimit"] = val;});});
    _read("monthlySaved").then((val) {setState(() {data["monthlySaved"] = val;});});
    _read("monthlyResetDate").then((val) {setState(() {data["monthlyResetDate"] = val;});});

    // This value is only available while the app is running.
    data["SpendValue"] = 0;
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
    }

    // This function won't run during this session anymore
    setState((){
      ready = true;
    });

    // Save Values
    _save("todayDate", data);
    _save("monthlySaved", data);
    _save("todaySpent", data);
    _save("monthlyResetDate", data);
  }

  // Two Main Screens for the app
  List<Widget> _children() => [
    SpendMoneyWidget(data: data),
    DisplayWidget(data: data),
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

    // While Data is loading, show empty screen
    if(data == null || data["monthlyResetDate"] == null) {
      return Scaffold(
          backgroundColor: Color.fromRGBO(149, 213, 178, 1),
      );
    }

    // Once Data loads, check if its a new day since last run.
    if(!ready)
      checkNewDay();

    // App Loads
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
      body: PageView(
          onPageChanged: (index) {
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
        ],
      ),
    );
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      pagecontroller.animateToPage(index, duration: Duration(milliseconds: 500), curve: Curves.ease);
    });
  }

  // Reading from Shared Preferences
  Future<double> _read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    double value = prefs.getDouble(key);
    if(value == null){return 0.0;}
    return value;
  }

  // Saving to Shared Preferences
  _save(String key, Map<String, double> data) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble(key, data[key]);
  }
}

