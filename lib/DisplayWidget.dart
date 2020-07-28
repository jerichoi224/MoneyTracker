import 'package:flutter/material.dart';
import "package:intl/intl.dart";

class DisplayWidget extends StatefulWidget {
  final Map<String, double> data;

  DisplayWidget({Key key, this.data}) : super(key: key);

  @override
  State createState() => _DisplayState();
}

class _DisplayState extends State<DisplayWidget> {
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
          _moneyText(widget.data["dailyLimit"] - widget.data["todaySpent"]),
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
}