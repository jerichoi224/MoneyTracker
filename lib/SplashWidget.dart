import 'package:flutter/material.dart';
import 'package:money_tracker/HomeWidget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashWidget extends StatefulWidget {
  final Map<String, double> data;
  final myController = TextEditingController();
  SplashWidget({Key key, this.data}) : super(key: key);

  @override
  State createState() => _SplashState();
}

class _SplashState extends State<SplashWidget>{
  @override

  void initState(){
    super.initState();

    var now = DateTime.now().toLocal();
    //Save current day as double with yyyyMMdd
    widget.data["monthlyResetDate"] = now.day.toDouble();
  }

  bool isNumeric(String s) {
    if (s == null) {
      return false;
    }
    return double.tryParse(s) != null;
  }

  finishSplash() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('seen', true);
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);

//    Navigator.of(context).pushReplacement(
//        new MaterialPageRoute(builder: (context) => new HomeWidget(data: widget.data)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
        Builder(
          builder: (context) =>
            new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(15),
                  child: Center(
                      child: Image(
                        image: AssetImage('assets/my_icon.png'),
                        width: 150,
                      )
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(40, 10, 40, 10),
                  child: Center(
                      child: Text(
                        "How much would you like to \nspend daily on average?",
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      )
                  )
                ),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  margin: EdgeInsets.fromLTRB(40, 0, 40, 0),
                  child: Center(
                    child: ListTile(
                        title: new Row(
                          children: <Widget>[
                            Flexible(
                                child: TextField(
                                  controller: widget.myController,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Enter Daily Limit',
                                  ),
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                )
                            )
                          ],
                        )
                    ),
                  )
                ),
                Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    margin: EdgeInsets.fromLTRB(40, 10, 40, 10),
                    color: Color.fromRGBO(149, 213, 178, 1),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          ListTile(
                              onTap:(){
                                if(widget.myController.text.isNotEmpty) {
                                  if(isNumeric(widget.myController.text)) {
                                    widget.data["dailyLimit"] =
                                        double.parse(widget.myController.text);
                                    _saveSP("dailyLimit", widget.data);
                                    finishSplash();
                                  }else{
                                    Scaffold.of(context).showSnackBar(SnackBar(
                                      content: Text('Your input is invalid. Please Check again'),
                                      duration: Duration(seconds: 3),
                                    ));
                                  }
                                }else{
                                  Scaffold.of(context).showSnackBar(SnackBar(
                                    content: Text('Please enter initial amount'),
                                    duration: Duration(seconds: 3),
                                  ));
                                }
                              },
                              title: Text("Start",
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
    );
  }

  // Saving to Shared Preferences
  _saveSP(String key, Map<String, double> data) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble(key, data[key]);
  }
}

