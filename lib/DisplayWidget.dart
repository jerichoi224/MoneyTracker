import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_tracker/database_helpers.dart';

class DisplayWidget extends StatefulWidget {
  final Map<String, double> data;
  final List<SubscriptionEntry> subscriptions;

  DisplayWidget({Key key, this.data, this.subscriptions}) : super(key: key);

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

  List<DateTime> calculateDaysInterval(DateTime startDate, DateTime endDate) {
    List<DateTime> days = [];
    DateTime tmp = DateTime(startDate.year, startDate.month, startDate.day, 12);
    while(DateTime(tmp.year, tmp.month, tmp.day) != endDate){
      tmp = tmp.add(new Duration(days: 1));
      days.add(DateTime(tmp.year, tmp.month, tmp.day));
    }

    return days;
  }


  void addSubscriptionEntry(SubscriptionEntry i, DateTime dt){

    SingleEntry subscriptionEntry = new SingleEntry();
    subscriptionEntry.day = DateFormat('yyyyMMdd').format(dt);
    subscriptionEntry.timestamp = DateTime(dt.year, dt.month, dt.day).millisecondsSinceEpoch;
    subscriptionEntry.amount = i.amount * -1;
    subscriptionEntry.content = i.content + " (Subscription)";

    if(dt.year == DateTime.now().year && dt.month == DateTime.now().month && dt.day == DateTime.now().day){
      widget.data["todaySpent"] -= i.amount;
    }else{
      widget.data["totalSaved"] -= i.amount;
    }

    _saveDB(subscriptionEntry);
  }

  // This will run on startup to check if a new day has past.
  void checkNewDay(){
    // Date depends on local
    DateTime now = DateTime.now().toLocal();
    double today = double.parse(getTodayString());

    double prev = widget.data["todayDate"];
    DateTime prevDate = DateTime(prev~/10000, (prev % 10000) ~/100, (prev % 100).toInt());

    // If its a new day, accumulate the savings into monthly saving and reset daily
    if(widget.data["todayDate"] != today){

      //Get 'yesterday' spending
      // Accumulate how much was saved yesterday
      widget.data["totalSaved"] += (widget.data["dailyLimit"] + widget.data["todaySpent"]);
      widget.data["todaySpent"] = 0.0;

      for(DateTime dt in calculateDaysInterval(prevDate, DateTime(now.year, now.month, now.day))) {
        for(SubscriptionEntry i in widget.subscriptions){
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
          print(dt);
          widget.data["totalSaved"] += widget.data["dailyLimit"];
        }
      }

      // New Date and reset
      widget.data["todayDate"] = today;

      _saveSP("todayDate", widget.data["todayDate"]);
      _saveSP("totalSaved", widget.data["totalSaved"]);
      try {
        setState(() {});
      }on Exception catch (_) {
      } catch (error) {
      }
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

  _saveDB(SingleEntry entry) async {
    DatabaseHelper helper = DatabaseHelper.instance;
    await helper.insert(entry);
  }
}