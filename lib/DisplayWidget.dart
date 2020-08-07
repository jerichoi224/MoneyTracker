import 'package:flutter/material.dart';

import 'package:money_tracker/database_helpers.dart';
import 'package:money_tracker/CurrencyInfo.dart';

class DisplayWidget extends StatefulWidget {
  final Map<String, num> numData;
  final List<SubscriptionEntry> subscriptions;
  final Map<String, String> stringData;

  DisplayWidget({Key key, this.numData, this.subscriptions, this.stringData}) : super(key: key);

  @override
  State createState() => _DisplayState();
}

class _DisplayState extends State<DisplayWidget>{

  void initState() {
    super.initState();
  }

  getRemaining(){
    return widget.numData["dailyLimit"] + widget.numData["todaySpent"];
  }

  getTotalSaved(){
    return widget.numData["totalSaved"];
  }

  String getMoneyString(num amount){
    return CurrencyInfo().getCurrencyText(widget.stringData["currency"], amount);
  }

  // Currently defaults is US Dollars
  Widget _moneyText(num amount) {
    return Center(
        child: Text(getMoneyString(amount),
            style: TextStyle(fontSize: 40.0, color: getColor(amount))));
  }

  // Returns color for text based on the amount.
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
          _moneyText(getRemaining()),
          new Padding(
            padding: new EdgeInsets.fromLTRB(0, 20, 0, 10),
            child:Center(
                child: Text("Total Saved",
                  style: TextStyle(fontSize: 20.0,),
                )
            ),
          ),
          _moneyText(getTotalSaved()),
      ],
    );
  }
}