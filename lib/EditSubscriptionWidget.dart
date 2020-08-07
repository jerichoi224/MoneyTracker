import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import 'package:flutter/services.dart';
import 'dart:math';

import 'package:money_tracker/database_helpers.dart';
import 'package:money_tracker/CurrencyInfo.dart';

class EditSubscriptionWidget extends StatefulWidget {
  final contentController = TextEditingController();
  final amountController = TextEditingController();
  final dateController = TextEditingController();

  final String currency;
  final String mode;
  final SubscriptionEntry item;
  final BuildContext ctx;

  EditSubscriptionWidget({Key key, this.mode, this.item, this.ctx, this.currency}) : super(key: key);

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
      yearlyRenewDate = DateTime(DateTime.now().toLocal().year, dt.month, dt.day);

      if(cycle == "monthly"){
        widget.dateController.text= dt.day.toString();
      }
    }

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

  bool isInt(String s) {
    if (s == null) {
      return false;
    }
    return int.tryParse(s) != null;
  }

  String getYearlyDate(){
    return yearlyRenewDate == null ? "" :DateFormat('MM/dd').format(yearlyRenewDate);
  }

  num roundDouble(num value, int places){
    num mod = pow(10.0, places);
    return ((value * mod).round()/ mod);
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
                                                    FocusScope.of(context).unfocus();
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
                                                Text(
                                                    'Subscription Renews on:'
                                                ),
                                                Spacer(),
                                                Flexible(
                                                    child: TextField(
                                                      controller: widget.dateController,
                                                      decoration: InputDecoration(
                                                        border: InputBorder.none,
                                                        hintText: "Enter Day",
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
                                                  initialDate: yearlyRenewDate == null ? new DateTime.now().toLocal() : yearlyRenewDate,
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
                                                  FocusScope.of(context).unfocus();
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
                                            if(!isNumeric(widget.amountController.text) ||
                                                (CurrencyInfo().getCurrencyDecimalPlaces(widget.currency) == 0 &&
                                                    !isInt(widget.amountController.text))) {
                                              Scaffold.of(context).showSnackBar(SnackBar(
                                                content: Text('Your Amount is invalid. Please Check again'),
                                                duration: Duration(seconds: 3),
                                              ));
                                              return;
                                            }
                                            // Check Date
                                            if(cycle == "monthly" && !isDate(widget.dateController.text)){
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
                                            entry.amount = roundDouble(num.parse(widget.amountController.text), 2);
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
                                              }else{
                                                Scaffold.of(widget.ctx).showSnackBar(SnackBar(
                                                  content: Text(widget.mode == "NEW" ? 'Subscription has been added!' : 'Subscription has been edited!'),
                                                  duration: Duration(seconds: 3),
                                                ));
                                              }
                                              DateTime now = DateTime.now().toLocal();
                                              entry.day = DateTime(now.year, now.month, day).millisecondsSinceEpoch;
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
}