import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import 'package:shared_preferences/shared_preferences.dart';

class SettingsWidget extends StatefulWidget {
  final myController = TextEditingController();

  final Map<String, double> data;
  SettingsWidget({Key key, this.data}) : super(key: key);

  @override
  State createState() => _SettingsState();
}

class _SettingsState extends State<SettingsWidget> {
  String currentDaily;
  String monthlyReset;

  NumberFormat moneyNf = NumberFormat.simpleCurrency(decimalDigits: 2);

  String getMonthlyResetString(){
    String num = widget.data["monthlyResetDate"].toInt().toString();
    if(num == "1") return "1st";
    if(num == "2") return "2nd";
    if(num == "3") return "3rd";
    return num + "th";
  }

  void resetMonthlySpending(){
    var now = DateTime.now().toLocal();
    double today = double.parse(now.day.toString());
    setState(() {
      widget.data["monthlyResetDate"] = today;
      widget.data["monthlySaved"] = 0.0;
    });
  }

  bool isNumeric(String s) {
    if (s == null) {
      return false;
    }
    return double.tryParse(s) != null;
  }

  showAlertDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = FlatButton(
      child: Text("Cancel"),
      onPressed:  () {Navigator.of(context).pop();},
    );
    Widget continueButton = FlatButton(
      child: Text("Reset"),
      onPressed: (){
        resetMonthlySpending();
        _save("monthlyResetDate", widget.data);
        Navigator.of(context).pop();
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text('Monthly usage reset'),
          duration: Duration(seconds: 3),
        ));
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Confirm Reset"),
      content: Text("Would you like to reset your Monthly Saving? Your cycle will reset to start today as well."),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    monthlyReset = getMonthlyResetString();
    currentDaily = moneyNf.format(widget.data["dailyLimit"]);
    return WillPopScope(
        onWillPop: () async{
          Navigator.pop(context, widget.data);
          return true;
        },
        child: new Scaffold(
          appBar: AppBar(
            title: Text("Settings"),
          ),
          body: Builder(
          builder: (context) =>
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.fromLTRB(10, 10, 0, 0),
                    child: Text("Change System Values",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey
                      ),
                    )
                  ),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    margin: EdgeInsets.all(8.0),
                    child: Column(
                      children: <Widget>[
                        ListTile(
                            title: new Row(
                              children: <Widget>[
                                new Text("Current daily limit"),
                                Spacer(),
                                new Text("$currentDaily")
                              ],
                            )
                        ),
                        ListTile(
                            title: new Row(
                              children: <Widget>[
                                Flexible(
                                  child: TextField(
                                    controller: widget.myController,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Change Daily Limit',
                                      ),
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.end,
                                  )
                                )
                              ],
                            )
                        ),
                        ListTile(
                            onTap: (){
                              showAlertDialog(context);
                            },
                            title: new Row(
                              children: <Widget>[
                                new Text("Reset Monthly Saving"),
                                Spacer(),
                                new Text("Resets on the $monthlyReset",
                                style: TextStyle(
                                  color: Colors.grey
                                ),
                                )
                              ],
                            )
                        )
                      ],
                    )
                  ),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    margin: EdgeInsets.fromLTRB(8, 0, 8, 0),
                      color: Color.fromRGBO(149, 213, 178, 1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          ListTile(
                            onTap:(){
                              if(widget.myController.text.isNotEmpty) {
                                if(isNumeric(widget.myController.text)) {
                                  widget.data["dailyLimit"] =
                                      double.parse(widget.myController.text);
                                  _save("dailyLimit", widget.data);
                                }else{
                                  Scaffold.of(context).showSnackBar(SnackBar(
                                    content: Text('Your input is invalid. Please Check again'),
                                    duration: Duration(seconds: 3),
                                  ));
                                  return;
                                }
                              }
                              Navigator.pop(context, widget.data);
                            },
                            title: Text("Save Setting",
                              style: TextStyle(
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                            )
                          )
                        ]
                    )
                  )
                ],
              )
            )
          )
        )
    );
  }

  _save(String key, Map<String, double> data) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble(key, data[key]);
  }
}