import 'package:flutter/material.dart';

class SettingsWidget extends StatefulWidget {
  final myController = TextEditingController();

  final Map<String, double> data;
  SettingsWidget({Key key, this.data}) : super(key: key);

  @override
  State createState() => _SettingsState();
}

class _SettingsState extends State<SettingsWidget> {
  double currentDaily;
  String monthlyReset;

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
    widget.data["monthlyResetDate"] = today;
    widget.data["todaySpent"] = 0.0;
    widget.data["monthlySaved"] = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    monthlyReset = getMonthlyResetString();
    currentDaily = widget.data["dailyLimit"];
    return WillPopScope(
        onWillPop: (){
          Navigator.pop(context, widget.data);
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
                                new Text("\$$currentDaily")
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
                              resetMonthlySpending();
                              setState(() {});
                              Scaffold.of(context).showSnackBar(SnackBar(
                                content: Text('Monthly usage reset'),
                                duration: Duration(seconds: 3),
                              ));
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
                              widget.data["dailyLimit"] = double.parse(widget.myController.text);
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
}