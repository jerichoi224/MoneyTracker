import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import 'database_helpers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class EditSubscriptionWidget extends StatefulWidget {
  final contentController = TextEditingController();
  final amountController = TextEditingController();
  final dateController = TextEditingController();

  final String mode;
  final SubscriptionEntry item;
  final BuildContext ctx;

  EditSubscriptionWidget({Key key, this.mode, this.item, this.ctx}) : super(key: key);

  @override
  State createState() => _EditSubscriptionState();
}

class _EditSubscriptionState extends State<EditSubscriptionWidget> {
  SubscriptionEntry entry;
  String cycle, content;
  double amount;
  int monthlyRenewDay;
  DateTime yearlyRenewDate;

  @override
  void initState() {
    super.initState();
    if(widget.mode == "NEW") {
      entry = new SubscriptionEntry();
      cycle = "monthly";
      monthlyRenewDay = 0;
    }
    if(widget.mode == "EDIT"){
      entry = widget.item;
      DateTime dt = DateTime.fromMillisecondsSinceEpoch(entry.day);

      cycle = entry.cycle == 0 ? "monthly" : "yearly";
      widget.contentController.text = entry.content;
      widget.amountController.text = entry.amount.toString();
      monthlyRenewDay = dt.day;
      yearlyRenewDate = DateTime(DateTime.now().toLocal().year, DateTime.now().toLocal().month, dt.day);

      if(cycle == "monthly"){
        widget.dateController.text= dt.day.toString();
      }
    }

    SystemChannels.lifecycle.setMessageHandler((msg){
      if(msg==AppLifecycleState.resumed.toString()) {
        if(this.mounted){
        _readSP("SubscriptionContentText").then((val) {setState(() {widget.contentController.text = val;});});
        _readSP("SubscriptionAmountText").then((val) {setState(() {widget.amountController.text = val;});});
        _readSP("SubscriptionYearlyRenewDate").then((val) {val != null ?? setState(() { yearlyRenewDate = DateTime.fromMillisecondsSinceEpoch(val);});});
        _readSP("SubscriptionMonthlyRenewDay").then((val) {setState(() {monthlyRenewDay = val;});});
        _readSP("cycle").then((val) {setState(() {cycle = val;});});
        }
      } else if(msg==AppLifecycleState.paused.toString() || msg==AppLifecycleState.inactive.toString()) {
        _saveSP("cycle", cycle);
        widget.contentController.text.isNotEmpty ?? _saveSP("SubscriptionContentText", widget.contentController.text);
        widget.amountController.text.isNotEmpty ?? _saveSP("SubscriptionAmountText", widget.amountController.text);
        yearlyRenewDate != null ?? _saveSP("SubscriptionYearlyRenewDate", yearlyRenewDate.millisecondsSinceEpoch);
        monthlyRenewDay != 0 ?? _saveSP("SubscriptionMonthlyRenewDay", monthlyRenewDay);
      }
      return null;
    });
  }

  // Check if the value is numeric
  bool isNumeric(String s) {
    if (s == null) {
      return false;
    }
    return double.tryParse(s) != null;
  }
  bool isDate(String s) {
    if(s == null) {
      return false;
    }
    return int.tryParse(s) != null && int.parse(s) < 32 && int.parse(s) > 0;
  }

  String getYearlyDate(){
    return yearlyRenewDate == null ? "" :DateFormat('MM/dd').format(yearlyRenewDate);
  }

  double roundDouble(double value, int places){
    double mod = pow(10.0, places);
    return ((value * mod).round().toDouble() / mod);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async{
          Navigator.pop(context, null);
          return true;
        },
          child: new GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: Scaffold(
                appBar: AppBar(
                  title: Text(
                    widget.mode == "NEW" ? "Add Subscription" : "Edit Subscription"
                  ),
                ),
                body: Builder(
                    builder: (context) => SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // Content
                            Container(
                                padding: EdgeInsets.fromLTRB(10, 10, 0, 0),
                                child: Text("Content",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey
                                  ),
                                )
                            ),
                            Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                              margin: EdgeInsets.all(8.0),
                              child: ListTile(
                                  title: new Row(
                                    children: <Widget>[
                                      Flexible(
                                          child: TextField(
                                            controller: widget.contentController,
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              hintText: 'What is this for?',
                                            ),
                                            keyboardType: TextInputType.text,
                                            textAlign: TextAlign.start,
                                          )
                                      )
                                    ],
                                  )
                              ),
                            ),
                            // Amount
                            Container(
                                padding: EdgeInsets.fromLTRB(10, 10, 0, 0),
                                child: Text("Amount",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey
                                  ),
                                )
                            ),
                            Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                              margin: EdgeInsets.all(8.0),
                              child: ListTile(
                                  title: new Row(
                                    children: <Widget>[
                                      Flexible(
                                          child: TextField(
                                            controller: widget.amountController,
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              hintText: 'How Much does this cost?',
                                            ),
                                            textAlign: TextAlign.start,
                                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                                          )
                                      )
                                    ],
                                  )
                              ),
                            ),
                            // Renew Date
                            Container(
                                padding: EdgeInsets.fromLTRB(10, 10, 0, 0),
                                child: Text("Renew Date",
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
                                          Text("Payment Cycle"),
                                          Spacer(),
                                          DropdownButton<String>(
                                            value: cycle,
                                            iconSize: 24,
                                            elevation: 16,
                                            underline: Container(
                                              height: 2,
                                            ),
                                            onChanged: (String newValue) {
                                              setState(() {
                                                cycle = newValue;
                                              });
                                            },
                                            items: <String>['monthly', 'yearly']
                                                .map<DropdownMenuItem<String>>((String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                          )
                                        ],
                                      )
                                  ),
                                  Visibility(
                                    visible: cycle == "monthly",
                                    child: ListTile(
                                        title: new Row(
                                          children: <Widget>[
                                            Flexible(
                                                child: TextField(
                                                  controller: widget.dateController,
                                                  decoration: InputDecoration(
                                                    border: InputBorder.none,
                                                    hintText: 'What day does the payment renew?',
                                                  ),
                                                  textAlign: TextAlign.start,
                                                  keyboardType: TextInputType.numberWithOptions(),
                                                )
                                            )
                                          ],
                                        )
                                    ),
                                  ),
                                  Visibility(
                                    visible: cycle == "yearly",
                                    child: ListTile(
                                        title: new Row(
                                          children: <Widget>[
                                            Text("Renew Date: " + getYearlyDate())
                                          ],
                                        ),
                                      trailing: IconButton(
                                        icon: Icon(Icons.calendar_today),
                                        onPressed: (){
                                          showDatePicker(
                                            context: context,
                                            initialDate: new DateTime.now().toLocal(),
                                            firstDate: new DateTime(DateTime.now().toLocal().year, 1, 1),
                                            lastDate: new DateTime(DateTime.now().toLocal().year, 12, 31),
                                            builder: (BuildContext context, Widget child) {
                                              return Theme(
                                                data: ThemeData.light().copyWith(
                                                  colorScheme: ColorScheme.light(
                                                    primary: Color.fromRGBO(149, 213, 178, 1),
                                                    onPrimary: Colors.white,
                                                  ),
                                                  buttonTheme: ButtonThemeData(
                                                    buttonColor: Color.fromRGBO(149, 213, 178, 1),
                                                  ),
                                                ),
                                                child: child,
                                              );
                                            },
                                          ).then((value) {
                                            setState(() {
                                              yearlyRenewDate = value;
                                            });
                                          });
                                        },
                                      )
                                    ),
                                  )
                                ]
                              )
                            ),
                            // Save Button
                            Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                                margin: EdgeInsets.fromLTRB(8, 0, 8, 0),
                                color: Color.fromRGBO(149, 213, 178, 1),
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      ListTile(
                                          onTap:(){
                                            // Check Amount
                                            if(!isNumeric(widget.amountController.text)) {
                                              Scaffold.of(context).showSnackBar(SnackBar(
                                                content: Text('Your Amount is invalid. Please Check again'),
                                                duration: Duration(seconds: 3),
                                              ));
                                              return;
                                            }
                                            // Check Date
                                            if(!isDate(widget.dateController.text)){
                                              Scaffold.of(context).showSnackBar(SnackBar(
                                                content: Text('Your Date is invalid. Please Check again'),
                                                duration: Duration(seconds: 3),
                                              ));
                                              return;
                                            }
                                            if(widget.contentController.text.isEmpty){
                                              Scaffold.of(context).showSnackBar(SnackBar(
                                                content: Text('Please enter what this subscription is about'),
                                                duration: Duration(seconds: 3),
                                              ));
                                              return;
                                            }
                                            entry.amount = roundDouble(double.parse(widget.amountController.text), 2);
                                            entry.content = widget.contentController.text;
                                            Map cycleMap = {"monthly": 0, "yearly": 1};
                                            entry.cycle = cycleMap[cycle];
                                            if(cycle == "yearly"){
                                              entry.day = yearlyRenewDate.millisecondsSinceEpoch;
                                            }else{
                                              int day = int.parse(widget.dateController.text);
                                              if(day > 28){
                                                day = 28;
                                                Scaffold.of(widget.ctx).showSnackBar(SnackBar(
                                                  content: Text('Day will be set to 28 instead for purpose of monthly recording.'),
                                                  duration: Duration(seconds: 3),
                                                ));
                                              }
                                              entry.day = DateTime(DateTime.now().toLocal().year, 1, day).millisecondsSinceEpoch;
                                            }
                                            Navigator.pop(context, entry);
                                          },
                                          title: Text(
                                          widget.mode == "NEW" ? "Add Subscription" : "Save Changes"
                                          ,
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
        )
    );
  }

  _saveSP(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();

    if(value is String) {prefs.setString(key, value);}
    else if(value is bool) {prefs.setBool(key, value);}
    else if(value is int) {prefs.setInt(key, value);}
    else if(value is double) {prefs.setDouble(key, value);}
    else {prefs.setStringList(key, value);}
  }

  Future<dynamic> _readSP(String key) async {
    final prefs = await SharedPreferences.getInstance();
    dynamic val = prefs.get(key);
    return val;
  }
}