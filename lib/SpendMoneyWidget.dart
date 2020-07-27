import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'database_helpers.dart';

class SpendMoneyWidget extends StatefulWidget {
  final Map<String, double> data;
  final List<Entry> todaySpendings;
  final Map<String, String> StringData;
  final _myController = TextEditingController();
  SpendMoneyWidget({Key key, this.data, this.todaySpendings, this.StringData}) : super(key: key);

  @override
  State createState() => _SpendMoneyState();
}

class _SpendMoneyState extends State<SpendMoneyWidget> {
  NumberFormat moneyNf = NumberFormat.simpleCurrency(decimalDigits: 2);
  String amount;

  @override
  void initState() {
    super.initState();

    widget.data["keypadVisibility"] = 1.0;
    widget._myController.text = widget.StringData["SpendContent"];

    KeyboardVisibility.onChange.listen((bool visible) {
      widget.data["keypadVisibility"] = 1.0;
      if(visible){
        widget.data["keypadVisibility"] = 0.0;
      }
      if (this.mounted) {
        setState(() {
        });
      }
    });

  }

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
      FocusScope.of(context).unfocus();
      double val = double.parse(amount)/100.0;
      if(val > 0) {
        String content = widget._myController.text.isEmpty
            ? ("No Description")
            : widget._myController.text;
        widget.data["todaySpent"] += val;
        Entry entry = Entry();

        DateTime dt = DateTime.now().toLocal();
        entry.timestamp = dt.millisecondsSinceEpoch;
        entry.day = dt.year.toString() + dt.month.toString() + dt.day.toString();
        entry.amount = val;
        entry.content = content;

        widget.todaySpendings.add(entry);
        _saveDB(entry);
        amount = "0";
        widget._myController.text = "";
      }
    }else if(s == "C"){
      amount = "0";
    }else{
      amount += s;
    }
    widget.StringData["SpendContent"] = widget._myController.text;
    setState(() {
      amount = amount;
      widget.data["SpendValue"] = double.parse(amount);
    });
  }

  @override
  Widget build(BuildContext context) {
    amount = widget.data["SpendValue"].toInt().toString();
    widget._myController.text = widget.StringData["SpendContent"];
    widget._myController.selection = TextSelection.fromPosition(TextPosition(offset: widget._myController.text.length));

    return new GestureDetector(
        onTap: () {
          widget.StringData["SpendContent"] = widget._myController.text;
          FocusScope.of(context).unfocus();
        },
        child:new Container(
          child: CustomScrollView(
              slivers: [
              SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[

                      new Container(
                        padding: new EdgeInsets.fromLTRB(0, 60, 0, 30),
                        child: new Text(moneyNf.format(double.parse(amount)/100.0),
                          textAlign: TextAlign.center,
                          style: new TextStyle(
                            fontSize: 50,
                          ),
                        ),
                      ),
                      ListTile(
                          title: new Row(
                            children: <Widget>[
                              Flexible(
                                  child: TextField(
                                    controller: widget._myController,
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      hintText: '(Optional) Enter Description',
                                    ),
                                    textAlign: TextAlign.start,

                                  )
                              )
                            ],
                          )
                      ),
                      new Expanded(child: new Container()),
                      new Row(
                          children: [
                            buildButton("Spend", null, Color.fromRGBO(149, 213, 178, 1)),
                          ]
                      ),
                      Visibility (
                        visible: widget.data["keypadVisibility"] == 1.0,
                        child: new Column(
                          children: [
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
                      ),
                    ],
                  )
                )
              ]
          )
        )
    );
  }

  _saveSP(String key, Map<String, double> data) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble(key, data[key]);
  }

  _saveDB(Entry entry) async {
    DatabaseHelper helper = DatabaseHelper.instance;
    int id = await helper.insert(entry);
    print('inserted row: $id');
  }
}