import 'package:flutter/material.dart';

class SpendMoneyWidget extends StatefulWidget {
  @override
  State createState() => _SpendMoneyState();
}

class _SpendMoneyState extends State<SpendMoneyWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Center(child:
        Text("Spend Money Display",
          style: TextStyle(fontSize: 20.0,),
        )
        ),
      ],
    );
  }
}