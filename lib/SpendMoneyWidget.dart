import 'package:flutter/material.dart';
import "package:intl/intl.dart";

class SpendMoneyWidget extends StatefulWidget {
  @override
  State createState() => _SpendMoneyState();
}

class _SpendMoneyState extends State<SpendMoneyWidget> {
  NumberFormat moneyNf = NumberFormat.simpleCurrency(decimalDigits: 2);

  String amount = "0";
  Widget buildButton(String s, [Icon i, Color c]){
    return new Expanded(
        child: new MaterialButton(
          child: i == null? new Text(s, style: TextStyle(fontSize: 20.0,),) : i,
          color: c,
          padding: new EdgeInsets.all(30.0),
          onPressed: () => {},
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      child: Column(
        children: <Widget>[
          new Container(
            padding: new EdgeInsets.symmetric(
              vertical: 40.0,
              horizontal:  12.0
            ),
            child: new Text(moneyNf.format(double.parse(amount)),
              textAlign: TextAlign.center,
              style: new TextStyle(
                fontSize: 40,
              ),
            ),
          ),
          new Expanded(child: new Divider()),
          new Column(
            children: [
              new Row(
                  children: [
                    buildButton("Spend", null, Colors.white54),
                  ]
              ),
              new Row(
                children: [
                  buildButton("1"),
                  buildButton("2"),
                  buildButton("3"),
                ],
              ),
              new Row(
                children: [
                  buildButton("4"),
                  buildButton("5"),
                  buildButton("6"),
                ],
              ),
              new Row(
                children: [
                  buildButton("7"),
                  buildButton("8"),
                  buildButton("9"),
                ],
              ),
              new Row(
                children: [
                  buildButton("."),
                  buildButton("0"),
                  buildButton("", Icon(Icons.backspace)),
                ],
              )
            ],
          )

          
        ],
      )
    );
  }
}