import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import 'database_helpers.dart';

class TodaySpendingWidget extends StatefulWidget {
  final Map<String, double> data;
  final List<Entry> todaySpendings;

  TodaySpendingWidget({Key key, this.data, this.todaySpendings}) : super(key: key);

  @override
  State createState() => _TodaySpendingState();
}

class _TodaySpendingState extends State<TodaySpendingWidget> {
  NumberFormat moneyNf = NumberFormat.simpleCurrency(decimalDigits: 2);
  int remaining, saved;

  Widget _moneyText(double a) {
    // round value to two decimal
    int rounded = (a * 100).toInt();
    a = rounded/100;

    return Center(
        child: Text(moneyNf.format(a),
            style: TextStyle(fontSize: 40.0, color: getColor(a))));
  }

  Color getColor(i) {
    if (i < 0) return Colors.red;
    if (i > 0) return Colors.lightGreen;
    return Colors.black;
  }

  List<Widget> spendingHistory(){
    List<Widget> history = new List<Widget>();
    for(Entry i in widget.todaySpendings.reversed){
      history.add(
          new Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
              margin: EdgeInsets.all(5.0),
              color: Colors.white,
              child: ListTile(
                onTap: (){

                },
                isThreeLine: true,
                dense: true,
                title: Text(moneyNf.format(i.amount)),
                subtitle: Text(i.content),
                trailing: Icon(Icons.more_vert),
              )
          )
      );
    }
    return history;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(0, 25, 0, 20),
            child: Center(
              child: Text(
                  "Today's Spending",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                )
              ),
            ),

          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: spendingHistory()
          )
        ]
      )
    );
  }
}