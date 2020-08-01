import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DisplayWidget extends StatefulWidget {
  final Map<String, double> data;

  DisplayWidget({Key key, this.data}) : super(key: key);

  @override
  State createState() => _DisplayState();
}

class _DisplayState extends State<DisplayWidget>{
  NumberFormat moneyNf = NumberFormat.simpleCurrency(decimalDigits: 2);

  void initState() {
    SystemChannels.lifecycle.setMessageHandler((msg){
      if(msg==AppLifecycleState.resumed.toString()) {
        checkNewDay();
        setState(() {});
      }
      return null;
    });

    super.initState();
  }

  String getTodayString(){
    DateTime dt = DateTime.now().toLocal();
    return DateFormat('yyyyMMdd').format(dt);
  }

  // This will run on startup to check if a new day has past.
  void checkNewDay(){
    // Date depends on local
    DateTime now = DateTime.now().toLocal();
    double today = double.parse(getTodayString());

    // If its a new day, accumulate the savings into monthly saving and reset daily
    if(widget.data["todayDate"] != today){
      widget.data["totalSaved"] += (widget.data["dailyLimit"] + widget.data["todaySpent"]);

      setState(() {});

      // If this app hasn't been opened for a few days, gotta add the missing amounts
      DateTime startOfDay = new DateTime(now.year, now.month, now.day);
      DateTime prev = new DateTime((widget.data["todayDate"]~/10000),
          ((widget.data["todayDate"]%10000)~/100), (widget.data["todayDate"]%100).toInt());

      if(startOfDay.difference(prev).inDays > 1){
        widget.data["totalSaved"] += (startOfDay.difference(prev).inDays - 1) * widget.data["dailyLimit"];
      }

      // New Date and reset
      widget.data["todayDate"] = today;
      widget.data["todaySpent"] = 0;

      _saveSP("todayDate", widget.data["todayDate"]);
      _saveSP("totalSaved", widget.data["totalSaved"]);
      setState((){});
    }
  }

  getRemaining(){
    return widget.data["dailyLimit"] + widget.data["todaySpent"];
  }

  getTotalSaved(){
    return widget.data["totalSaved"];
  }

  // Currently works for Dollars
  Widget _moneyText(double a) {
    // round value to two decimal
    int rounded = (a * 100).round().toInt();
    return Center(
        child: Text(moneyNf.format(rounded/100.0),
            style: TextStyle(fontSize: 40.0, color: getColor(a))));
  }

  // Returns color for text based on the amount.
  Color getColor(i) {
    if (i < 0) return Colors.red;
    if (i > 0) return Colors.lightGreen;
    return Colors.black;
  }


  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Padding(
            padding: new EdgeInsets.fromLTRB(0, 30, 0, 10),
            child:Center(
                child: Text("Remaining Today",
                  style: TextStyle(fontSize: 20.0,),
                )
            ),
          ),
          _moneyText(getRemaining()),
          new Padding(
            padding: new EdgeInsets.fromLTRB(0, 20, 0, 10),
            child:Center(
                child: Text("Total Saved",
                  style: TextStyle(fontSize: 20.0,),
                )
            ),
          ),
          _moneyText(getTotalSaved()),
      ],
    );
  }

  _saveSP(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble(key, value);
  }
}