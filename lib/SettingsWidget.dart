import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import 'package:shared_preferences/shared_preferences.dart';

class SettingsWidget extends StatefulWidget {
  final amountController = TextEditingController();
  final dateController = TextEditingController();

  final Map<String, double> data;
  SettingsWidget({Key key, this.data}) : super(key: key);

  @override
  State createState() => _SettingsState();
}

class _SettingsState extends State<SettingsWidget> {
  String currentDaily, monthlyReset;
  bool showSaveButton, showEntireHistory;

  NumberFormat moneyNf = NumberFormat.simpleCurrency(decimalDigits: 2);


  @override
  void initState() {
    super.initState();
    showSaveButton = widget.data["disableSave"] == 0.0;
    showEntireHistory = widget.data["historyMode"] == 1.0;
  }

  String getMonthlyResetString(){
    String num = widget.data["monthlyResetDate"].toInt().toString();
    if(num == "1") return "1st";
    if(num == "2") return "2nd";
    if(num == "3") return "3rd";
    return num + "th";
  }

  bool isDate(String s) {
    if(s == null) {
      return false;
    }
    return int.tryParse(s) != null && int.parse(s) < 32 && int.parse(s) > 0;
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
        if(widget.dateController.text.isNotEmpty) {
          if(isDate(widget.dateController.text)) {
            widget.data["monthlyResetDate"] =
                double.parse(widget.dateController.text);
            widget.data["monthlySaved"] = 0.0;
            _save("monthlyResetDate", widget.data);
            _save("monthlySaved", widget.data);
            Navigator.of(context).pop();
            setState(() {});
            Scaffold.of(context).showSnackBar(SnackBar(
              content: Text('Monthly usage reset'),
              duration: Duration(seconds: 3),
            ));
          }else{
            Scaffold.of(context).showSnackBar(SnackBar(
              content: Text('Your input is invalid. Please Check again'),
              duration: Duration(seconds: 2),
            ));
          }
        }
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Reset will clear monthly savings",
          style: TextStyle(
            fontSize: 18
          )
      ),
      content: new TextField(
        controller: widget.dateController,
        decoration: InputDecoration(hintText: "Enter new reset day"),
        keyboardType: TextInputType.number,
      ),
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
                    child: Text("System Values",
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
                                    controller: widget.amountController,
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
                  Container(
                      padding: EdgeInsets.fromLTRB(10, 10, 0, 0),
                      child: Text("System UI",
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
                                  new Text("Show Save Button"),
                                  Spacer(),
                                  Switch(
                                    value: showSaveButton,
                                    onChanged: (value){
                                      setState(() {
                                        showSaveButton = value;
                                      });
                                    },
                                    activeTrackColor: Color.fromRGBO(114, 163, 136, 1),
                                    activeColor: Color.fromRGBO(149, 213, 178, 1),
                                  ),
                                ],
                              )
                          ),
                          ListTile(
                              title: new Row(
                                children: <Widget>[
                                  new Text("Show Entire History"),
                                  Spacer(),
                                  Switch(
                                    value: showEntireHistory,
                                    onChanged: (value){
                                      setState(() {
                                        showEntireHistory = value;
                                      });
                                    },
                                    activeTrackColor: Color.fromRGBO(114, 163, 136, 1),
                                    activeColor: Color.fromRGBO(149, 213, 178, 1),
                                  ),
                                ],
                              )
                          ),
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
                              if(widget.amountController.text.isNotEmpty) {
                                if(isNumeric(widget.amountController.text)) {
                                  widget.data["dailyLimit"] =
                                      double.parse(widget.amountController.text);
                                  _save("dailyLimit", widget.data);
                                }else{
                                  Scaffold.of(context).showSnackBar(SnackBar(
                                    content: Text('Your input is invalid. Please Check again'),
                                    duration: Duration(seconds: 3),
                                  ));
                                  return;
                                }
                              }

                              // Checkbox for Disabling Save Button
                              widget.data["disableSave"] = 1.0;
                              if(showSaveButton){
                                widget.data["disableSave"] = 0.0;
                              }
                              _save("disableSave", widget.data);

                              // Checkbox for Disabling Save Button
                              widget.data["historyMode"] = 0.0;
                              if(showEntireHistory){
                                widget.data["historyMode"] = 1.0;
                              }
                              _save("historyMode", widget.data);

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