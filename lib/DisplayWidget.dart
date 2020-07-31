import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import 'database_helpers.dart';

class DisplayWidget extends StatefulWidget {
  final Map<String, double> data;

  DisplayWidget({Key key, this.data}) : super(key: key);

  @override
  State createState() => _DisplayState();
}

class _DisplayState extends State<DisplayWidget> {
  NumberFormat moneyNf = NumberFormat.simpleCurrency(decimalDigits: 2);
  double todaySpent;
  List<Entry> todaySpendings;

  void initState() {
    super.initState();

    // Get the Amount Spent today
    todaySpent = 0;
    _queryDayDB(DateFormat('yyyyMMdd').format(DateTime.now().toLocal())).then((entries){
      setState(() {
        todaySpendings = entries;
        for(Entry i in todaySpendings){
          todaySpent += i.amount;
        }
      }
      );});

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
          _moneyText(widget.data["dailyLimit"] - todaySpent),
          new Padding(
            padding: new EdgeInsets.fromLTRB(0, 20, 0, 10),
            child:Center(
                child: Text("Monthly Saving",
                  style: TextStyle(fontSize: 20.0,),
                )
            ),
          ),
          _moneyText(widget.data["monthlySaved"]),
      ],
    );
  }

  Future<List<Entry>> _queryDayDB(String day) async {
    DatabaseHelper helper = DatabaseHelper.instance;
    return await helper.queryDay(day);
  }
}