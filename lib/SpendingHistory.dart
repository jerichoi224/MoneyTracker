import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import 'package:money_tracker/EditWidget.dart';
import 'database_helpers.dart';
import 'package:flutter/services.dart';

class SpendingHistoryWidget extends StatefulWidget {
  final Map<String, double> data;
    final Map<String, String> stringData;

  SpendingHistoryWidget({Key key, this.data, this.stringData}) : super(key: key);

  @override
  State createState() => _SpendingHistoryState();
}

class _SpendingHistoryState extends State<SpendingHistoryWidget> with WidgetsBindingObserver{
  NumberFormat moneyUS = NumberFormat.simpleCurrency(decimalDigits: 2);
  NumberFormat moneyKor = NumberFormat.currency(symbol: "₩", decimalDigits: 0);

  int remaining, saved;
  String dayString;
  DateTime _day;
  List<SingleEntry> tempSpendingList;

  @override
  void initState(){
    WidgetsBinding.instance.addObserver(this);
    super.initState();

    SystemChannels.lifecycle.setMessageHandler((msg){
      if(msg==AppLifecycleState.resumed.toString())
      if(this.mounted) {
        _day = DateTime.now().toLocal();
        setState(() {});
      }
      return null;
    });

    _day = DateTime.now().toLocal();
    tempSpendingList = new List<SingleEntry>();

    _queryAllDB().then((entries){
      setState(() {tempSpendingList = entries;
      });});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String dayToString(DateTime dt){
    return DateFormat('yyyy/MM/dd').format(dt);
  }

  TextSpan _moneyText(double a) {
    if(widget.stringData["locale"] == "KOR"){
      return TextSpan(text: moneyKor.format(a.toInt()),
          style: TextStyle(color: getColor(a)));
    }
    // round value to two decimal
    int rounded = (a * 100).round().toInt();
    return TextSpan(text: moneyUS.format(rounded/100.0),
        style: TextStyle(color: getColor(a)));
  }

  Color getColor(i) {
    if (i < 0) return Colors.red;
    if (i > 0) return Colors.green;
    return Colors.black;
  }

  void _openEditWidget(SingleEntry item) async {
    // start the SecondScreen and wait for it to finish with a result

    String oldContent = item.content;
    double oldAmount = item.amount;

    final SingleEntry result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditWidget(item: item, locale: widget.stringData["locale"],),
        )
    );

    if(result.content == oldContent && result.amount == oldAmount){
      return;
    }

    for(SingleEntry i in tempSpendingList){
      if(i.id == result.id){
        i.content = result.content;
        i.amount = result.amount;
        if(i.day == DateFormat('yyyyMMdd').format(DateTime.now().toLocal())) {
          widget.data["todaySpent"] -= oldAmount;
          widget.data["todaySpent"] += result.amount;
        }else{
          widget.data["totalSaved"] -= oldAmount;
          widget.data["totalSaved"] += result.amount;
        }
        _updateDB(i);
      }
    }
    // Update any values that have changed.
    setState(() {});
  }

  titleText(){
    if(widget.data["historyMode"] == 1.0){
      return "Spending History";
    }
    return dayToString(_day) == dayToString(DateTime.now().toLocal()) ? "Today's Spending" : "Spendings on $dayString";
  }

  _popUpMenuButton(SingleEntry i) {
    return PopupMenuButton(
      icon: Icon(Icons.more_vert),
      onSelected: (selectedIndex) { // add this property
        if(selectedIndex == 1){
          _deleteDB(i.id);
          tempSpendingList.remove(i);
          if(i.day == DateFormat('yyyyMMdd').format(DateTime.now().toLocal()))
            widget.data["todaySpent"] -= i.amount;
          else
            widget.data["totalSaved"] -= i.amount;
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

  getTimeText(SingleEntry i){
    DateTime dt = new DateTime.fromMillisecondsSinceEpoch(i.timestamp);
    return "\t\t(" + DateFormat('h:mm a').format(dt) + ")";
  }

  List<Widget> spendingHistory(){
    List<Widget> history = new List<Widget>();
    DateTime tmp = new DateTime(0);
    for(SingleEntry i in tempSpendingList.reversed){
      // If In Daily Mode, skip anything from other dates
      if(widget.data["historyMode"] == 0.0 && i.day != DateFormat('yyyyMMdd').format(_day)){
        continue;
      }
      // If in Entire History Mode, show date changes
      if(widget.data["historyMode"] == 1.0 && DateFormat('yyyyMMdd').format(tmp)
          != DateFormat('yyyyMMdd').format(DateTime.fromMillisecondsSinceEpoch(i.timestamp))){
        tmp = DateTime.fromMillisecondsSinceEpoch(i.timestamp);
        history.add(
          Padding(
            padding: EdgeInsets.fromLTRB(0, 5, 0, 5),
            child: Text(DateFormat('yyyy/MM/dd').format(tmp),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black54
              ),
            )
          )
        );
      }
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
                        _moneyText(i.amount),
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
              leading: Visibility(
                visible: widget.data["historyMode"] == 0.0,
                child: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: (){
                    showDatePicker(
                        context: context,
                        initialDate: _day,
                        firstDate: DateTime(2001),
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
              ),
              title: Text(titleText(),
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
    await helper.deleteSingleEntry(id);
  }

  _updateDB(SingleEntry entry) async{
    DatabaseHelper helper = DatabaseHelper.instance;
    await helper.updateSingleEntry(entry);
  }

  Future<List<SingleEntry>> _queryAllDB() async {
    DatabaseHelper helper = DatabaseHelper.instance;
    return await helper.queryAll();
  }
}