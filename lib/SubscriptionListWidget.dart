import 'package:flutter/material.dart';
import "package:intl/intl.dart";

import 'package:money_tracker/EditSubscriptionWidget.dart';
import 'package:money_tracker/database_helpers.dart';
import 'package:money_tracker/CurrencyInfo.dart';


class SubscriptionListWidget extends StatefulWidget {
  final List<SubscriptionEntry> subscriptions;
  final String currency;

  SubscriptionListWidget({Key key, this.subscriptions, this.currency}) : super(key: key);

  @override
  State createState() => _SubscriptionListState();
}

class _SubscriptionListState extends State<SubscriptionListWidget> {
  List<SubscriptionEntry> subscriptionList;

  @override
  void initState() {
    super.initState();
    subscriptionList = new List<SubscriptionEntry>();

    _queryDBAllSubscription().then((entries) {
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

  void _openEditWidget(SubscriptionEntry item, BuildContext ctx) async {
    final SubscriptionEntry result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditSubscriptionWidget(mode: "EDIT", item: item, ctx: ctx, currency: widget.currency,),
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
      _updateDBSubscription(result);
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
          _deleteDBSubscription(i.id);
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
    List<Widget> subscriptions = new List<Widget>();
    for (SubscriptionEntry i in subscriptionList) {
      subscriptions.add(new Card(
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
                        text: CurrencyInfo().getCurrencyText(widget.currency, i.amount),
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
    return subscriptions.length > 0 ? subscriptions : List.from([
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

  _deleteDBSubscription(int id) async {
    DatabaseHelper helper = DatabaseHelper.instance;
    await helper.deleteSubscription(id);
  }

  _updateDBSubscription(SubscriptionEntry entry) async {
    DatabaseHelper helper = DatabaseHelper.instance;
    await helper.updateSubscription(entry);
  }

  Future<List<SubscriptionEntry>> _queryDBAllSubscription() async {
    DatabaseHelper helper = DatabaseHelper.instance;
    return await helper.queryAllSubscriptions();
  }
}
