import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import 'package:money_tracker/EditSubscriptionWidget.dart';
import 'database_helpers.dart';
import 'dart:math';

class SubscriptionListWidget extends StatefulWidget {
  final Map<String, double> data;
  final List<SubscriptionEntry> subscriptions;
  final String locale;

  SubscriptionListWidget({Key key, this.data, this.subscriptions, this.locale}) : super(key: key);

  @override
  State createState() => _SubscriptionListState();
}

class _SubscriptionListState extends State<SubscriptionListWidget> {
  NumberFormat moneyUS = NumberFormat.simpleCurrency(decimalDigits: 2);
  NumberFormat moneyKor = NumberFormat.currency(symbol: "₩", decimalDigits: 0);
  List<SubscriptionEntry> subscriptionList;

  @override
  void initState() {
    super.initState();
    subscriptionList = new List<SubscriptionEntry>();

    _queryAllDB().then((entries) {
      setState(() {
        subscriptionList = entries;
        widget.subscriptions.clear();
        for(SubscriptionEntry i in subscriptionList)
          widget.subscriptions.add(i);
      });
    });
  }

  String getDaySuffix(int day){
    if(day == 1) return "1st";
    if(day == 2) return "2nd";
    if(day == 3) return "3rd";
    return day.toString() + "th";
  }

  double roundDouble(double value, int places){
    double mod = pow(10.0, places);
    return ((value * mod).round().toDouble() / mod);
  }

  void _openEditWidget(SubscriptionEntry item, BuildContext ctx) async {
    final SubscriptionEntry result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditSubscriptionWidget(mode: "EDIT", item: item, ctx: ctx, locale: widget.locale,),
        ));

    if(result != null){
      for(SubscriptionEntry i in widget.subscriptions){
        if(i.id == result.id){
          i.day = result.day;
          i.cycle = result.cycle;
          i.content = result.content;
          i.amount = result.amount;
        }
      }
      _updateDB(result);
      setState(() {});
    }
    // Update any values that have changed.
  }

  _popUpMenuButton(SubscriptionEntry i, BuildContext context) {
    return PopupMenuButton(
      icon: Icon(Icons.more_vert),
      onSelected: (selectedIndex) {
        // add this property
        if (selectedIndex == 1) {
          _deleteDB(i.id);
          subscriptionList.remove(i);
          widget.subscriptions.remove(i);
          setState(() {});
        } else if (selectedIndex == 0) {
          _openEditWidget(i, context);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          child: Text("Edit"),
          value: 0,
        ),
        PopupMenuItem(
          child: Text("Delete"),
          value: 1,
        ),
      ],
    );
  }

  getRenewDate(SubscriptionEntry i) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(i.day);
    return i.cycle == 0 ? getDaySuffix(date.day) : DateFormat("MM/dd").format(date);
  }

  List<Widget> getSubscriptions(BuildContext ctx) {
    List<Widget> history = new List<Widget>();
    for (SubscriptionEntry i in subscriptionList) {
      history.add(new Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          margin: EdgeInsets.all(5.0),
          color: Colors.white,
          child: ListTile(
              dense: true,
              title: RichText(
                text: TextSpan(
                  children: <TextSpan>[
                    TextSpan(
                        text: widget.locale == "KOR" ? moneyKor.format(i.amount) : moneyUS.format(i.amount),
                      style: TextStyle(color: Colors.black)
                    ),
                    TextSpan(
                        text: " (Renews on: " + getRenewDate(i) + ")",
                        style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              subtitle: Text(i.content == "" ? "No Description" : i.content),
              trailing: _popUpMenuButton(i, ctx))));
    }
    return history.length > 0 ? history : List.from([
      Padding(
        padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
        child: Center(child: Text("Nothing Found!"))
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: AppBar(
          title: Text("Subscription List"),
        ),
        body: Builder(
          builder: (context) =>
            SingleChildScrollView(
                  child: Column(
                      children: <Widget>[
                        Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: getSubscriptions(context))
                      ]
                  )
            )
        )
    );
  }

  _deleteDB(int id) async {
    DatabaseHelper helper = DatabaseHelper.instance;
    await helper.deleteSubscription(id);
  }

  _updateDB(SubscriptionEntry entry) async {
    DatabaseHelper helper = DatabaseHelper.instance;
    await helper.updateSubscription(entry);
  }

  Future<List<SubscriptionEntry>> _queryAllDB() async {
    DatabaseHelper helper = DatabaseHelper.instance;
    return await helper.queryAllSubscriptions();
  }
}
