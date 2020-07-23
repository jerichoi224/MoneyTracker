import 'package:flutter/material.dart';

class SettingsWidget extends StatefulWidget {
  @override
  State createState() => _SettingsState();
}

class _SettingsState extends State<SettingsWidget> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Settings"),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Center(
                child:Text("Settings Display",
                  style: TextStyle(fontSize: 20.0,),
                )
            )
          ],
        )
    );
  }
}