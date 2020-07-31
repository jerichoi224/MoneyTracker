import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import 'package:money_tracker/EditWidget.dart';
import 'database_helpers.dart';
import 'package:flutter/services.dart';

class SpendingHistoryWidget extends StatefulWidget {
  final Map<String, double> data;

  SpendingHistoryWidget({Key key, this.data}) : super(key: key);

  @override
  State createState() => _SpendingHistoryState();
}

class _SpendingHistoryState extends State<SpendingHistoryWidget> {
  NumberFormat moneyNf = NumberFormat.simpleCurrency(decimalDigits: 2);
  int remaining, saved;
  String dayString;
  DateTime _day, firstDate;
  List<Entry> tempSpendingList;

  @override
  void initState(){
    super.initState();

    SystemChannels.lifecycle.setMessageHandler((msg){
      if(msg==AppLifecycleState.resumed.toString())
      setState((){
        _day = DateTime.now().toLocal();
      });
      return null;
    });

    _day = DateTime.now().toLocal();
    tempSpendingList = new List<Entry>();

    _queryAllDB().then((entries){
      setState(() {tempSpendingList = entries;
      });});
    firstDate = DateTime.fromMillisecondsSinceEpoch(widget.data["firstDay"].toInt());
  }

  String dayToString(DateTime dt){
    return DateFormat('yyyy/MM/dd').format(dt);
  }

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

    for(Entry i in tempSpendingList){
      if(i.id == result.id){
        i.content = result.content;
        i.amount = result.amount;
        _updateDB(i);
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
          _deleteDB(i.id);
          tempSpendingList.remove(i);
          setState(() {});
        }
        else if(selectedIndex == 0){
          _openEditWidget(i);
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

  getTimeText(Entry i){
    DateTime dt = new DateTime.fromMillisecondsSinceEpoch(i.timestamp);
    return "\t\t(" + DateFormat('h:mm a').format(dt) + ")";
  }

  List<Widget> spendingHistory(){
    List<Widget> history = new List<Widget>();
    for(Entry i in tempSpendingList.reversed){
      if(i.day == DateFormat('yyyyMMdd').format(_day)) {
        history.add(
            new Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0)),
                margin: EdgeInsets.all(5.0),
                color: Colors.white,
                child: ListTile(
                    dense: true,
                    title: RichText(
                      text: TextSpan(
                        children: <TextSpan>[
                          TextSpan(text: moneyNf.format(i.amount),
                              style: TextStyle(color: Colors.black)),
                          TextSpan(text: getTimeText(i),
                              style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                    subtitle: Text(
                        i.content == "" ? "No Description" : i.content),
                    trailing: _popUpMenuButton(i)
                )
            )
        );
      }
    }
    return history.length > 0 ? history : List.from(
        [Text("Nothing Found!")]);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(0, 25, 0, 20),
            child: ListTile(
              dense: true,
              leading: IconButton(
                icon: Icon(Icons.calendar_today),
                onPressed: (){
                  showDatePicker(
                      context: context,
                      initialDate: _day,
                      firstDate: firstDate,
                      lastDate: DateTime.now(),
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
                      _day = value != null? value : _day;
                      dayString = dayToString(_day);
                    });
                  });
                },
              ),
              title: Text(
                    dayToString(_day) == dayToString(DateTime.now().toLocal()) ?
                    "Today's Spending" : "Spendings on $dayString",
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

  _deleteDB(int id) async{
    DatabaseHelper helper = DatabaseHelper.instance;
    await helper.delete(id);
  }

  _updateDB(Entry entry) async{
    DatabaseHelper helper = DatabaseHelper.instance;
    await helper.update(entry);
  }

  Future<List<Entry>> _queryAllDB() async {
    DatabaseHelper helper = DatabaseHelper.instance;
    return await helper.queryAll();
  }
}