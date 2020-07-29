import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import 'package:money_tracker/EditWidget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helpers.dart';

class TodaySpendingWidget extends StatefulWidget {
  final Map<String, double> data;
  final List<Entry> todaySpendings;

  TodaySpendingWidget({Key key, this.data, this.todaySpendings}) : super(key: key);

  @override
  State createState() => _TodaySpendingState();
}

class _TodaySpendingState extends State<TodaySpendingWidget> {
  NumberFormat moneyNf = NumberFormat.simpleCurrency(decimalDigits: 2);
  int remaining, saved;

  Widget _moneyText(double a) {
    // round value to two decimal
    int rounded = (a * 100).toInt();
    a = rounded/100;

    return Center(
        child: Text(moneyNf.format(a),
            style: TextStyle(fontSize: 40.0, color: getColor(a))));
  }

  Color getColor(i) {
    if (i < 0) return Colors.red;
    if (i > 0) return Colors.lightGreen;
    return Colors.black;
  }

  void _openEditWidget(Entry item) async {
    // start the SecondScreen and wait for it to finish with a result

    String oldContent = item.content;
    double oldAmount = item.amount;

    final Entry result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditWidget(item: item),
        ));

    if(result.content == oldContent && result.amount == oldAmount){
      return;
    }

    for(Entry i in widget.todaySpendings){
      if(i.id == result.id){
        i.content = result.content;
        i.amount = result.amount;
        _DBUpdate(i);
      }
    }

    // Update any values that have changed.
    setState(() {});
  }

  _popUpMenuButton(Entry i) {
    return PopupMenuButton(
      icon: Icon(Icons.more_vert),
      onSelected: (selectedIndex) { // add this property
        if(selectedIndex == 1){
          widget.todaySpendings.remove(i);
          _DBDelete(i.id);
        }
        else if(selectedIndex == 0){
          _openEditWidget(i);
        }
        setState(() {
        });
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

  getTimeText(Entry i){
    DateTime dt = new DateTime.fromMillisecondsSinceEpoch(i.timestamp);
    return "\t\t(" + DateFormat('h:mm a').format(dt) + ")";
  }

  List<Widget> spendingHistory(){
    List<Widget> history = new List<Widget>();
    for(Entry i in widget.todaySpendings.reversed){
      history.add(
          new Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
              margin: EdgeInsets.all(5.0),
              color: Colors.white,
              child: ListTile(
                dense: true,
                title: RichText(
                  text: TextSpan(
                    children: <TextSpan>[
                      TextSpan(text: moneyNf.format(i.amount), style: TextStyle(color: Colors.black)),
                      TextSpan(text: getTimeText(i), style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                subtitle: Text(i.content == "" ? "No Description" : i.content),
                trailing: _popUpMenuButton(i)
              )
          )
      );
    }
    return history;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(0, 25, 0, 20),
            child: Center(
              child: Text(
                  "Today's Spending",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                )
              ),
            ),

          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: spendingHistory()
          )
        ]
      )
    );
  }

  // Saving to Shared Preferences
  _saveSP(String key, Map<String, double> data) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble(key, data[key]);
  }

  _DBDelete(int id) async{
    DatabaseHelper helper = DatabaseHelper.instance;
    await helper.delete(id);
  }

  _DBUpdate(Entry entry) async{
    DatabaseHelper helper = DatabaseHelper.instance;
    await helper.update(entry);
  }
}