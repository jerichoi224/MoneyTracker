import 'package:flutter/material.dart';
import "package:intl/intl.dart";

class DisplayWidget extends StatefulWidget {
  @override
  State createState() => _DisplayState();
}

class _DisplayState extends State<DisplayWidget> {
  NumberFormat moneyNf = NumberFormat.simpleCurrency(decimalDigits: 2);
  int remaining, saved;

  Widget _moneyText(double a) {
    return Center(
        child: Text(
            moneyNf.format(a),
            style: TextStyle(
                fontSize: 40.0,
                color: a > 0 ? Colors.lightGreen : Colors.red
            )
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Center(child:
        Text("Remaining Amount",
          style: TextStyle(fontSize: 20.0,),
        )
        ),
        _moneyText(-10),
        new Padding(padding: new EdgeInsets.all(10.0)),
        Center(child:
        Text(
          "Saved this week",
          style: TextStyle(fontSize: 20.0,),
        )
        ),
        _moneyText(40.0)

      ],
    );
  }
}