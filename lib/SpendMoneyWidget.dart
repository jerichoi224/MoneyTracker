import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import 'package:shared_preferences/shared_preferences.dart';

class SpendMoneyWidget extends StatefulWidget {
  final Map<String, double> data;
  SpendMoneyWidget({Key key, this.data}) : super(key: key);

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
          padding: new EdgeInsets.all(20.0),
          onPressed: () => buttonPressed(s),
        )
    );
  }

  void buttonPressed(String s){
    if(s == "erase") {
      if(amount.length > 1) {
        amount = amount.substring(0, amount.length - 1);
      }else{
        amount = "0";
      }
    }else if(s == "Spend"){
      widget.data["todaySpent"] += double.parse(amount)/100.0;
      _save("todaySpent", widget.data["todaySpent"]);
      amount = "0";
    }else if(s == "C"){
      amount = "0";
    }else{
      amount += s;
    }
    setState(() {amount = amount;});
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      child: Column(
        children: <Widget>[
          new Container(
            padding: new EdgeInsets.fromLTRB(0, 60, 0, 0),
            child: new Text(moneyNf.format(double.parse(amount)/100.0),
              textAlign: TextAlign.center,
              style: new TextStyle(
                fontSize: 50,
              ),
            ),
          ),
          new Expanded(child: new Divider()),
          new Column(
            children: [
              new Row(
                  children: [
                    buildButton("Spend", null, Color.fromRGBO(149, 213, 178, 1)),
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
                  buildButton("C"),
                  buildButton("0"),
                  buildButton("erase", Icon(Icons.backspace)),
                ],
              )
            ],
          )
        ],
      )
    );
  }

  _save(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble(key, value);
  }
}