import 'package:flutter/material.dart';
import 'package:money_tracker/CurrencyInfo.dart';

import 'package:money_tracker/database_helpers.dart';


class EditSpendingWidget extends StatefulWidget {
  final contentController = TextEditingController();
  final amountController = TextEditingController();

  final String currency;
  final SpendingEntry item;

  EditSpendingWidget({Key key, this.item, this.currency}) : super(key: key);

  @override
  State createState() => _EditSpendingState();
}

class _EditSpendingState extends State<EditSpendingWidget> {

  // Check if the value is numeric
  bool isNumeric(String s) {
    if (s == null) {
      return false;
    }
    return double.tryParse(s) != null;
  }

  bool isInt(String s) {
    if (s == null) {
      return false;
    }
    return int.tryParse(s) != null;
  }

  String getMoneyString(num amount){
    return CurrencyInfo().getCurrencyText(widget.currency, amount);
  }

  @override
  Widget build(BuildContext context) {
    widget.amountController.text = widget.item.amount.toString();
    widget.contentController.text = widget.item.content;

    return WillPopScope(
        onWillPop: () async{
          Navigator.pop(context, widget.item);
          return true;
        },
        child: new Scaffold(
            appBar: AppBar(
              title: Text("Edit Entry"),
            ),
            body: Builder(
                builder: (context) =>
                    SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                                padding: EdgeInsets.fromLTRB(10, 10, 0, 0),
                                child: Text("Amount of Spending",
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
                                              hintText: 'Spending Amount',
                                            ),
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.start,
                                          )
                                      )
                                    ],
                                  )
                              ),
                            ),
                            Container(
                                padding: EdgeInsets.fromLTRB(10, 10, 0, 0),
                                child: Text("Description",
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
                                            style: TextStyle(height: 1.5),
                                            minLines: 3,
                                            maxLines: 3,
                                            controller: widget.contentController,
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              hintText: 'Enter what this spending was for',
                                            ),
                                            textAlign: TextAlign.start,
                                          )
                                      )
                                    ],
                                  )
                              ),
                            ),
                            Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                                margin: EdgeInsets.fromLTRB(8, 0, 8, 0),
                                color: Color.fromRGBO(155, 195, 255, 1),
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      ListTile(
                                          onTap:(){
                                            // Invalid input
                                            if(!isNumeric(widget.amountController.text) ||
                                                (CurrencyInfo().getCurrencyDecimalPlaces(widget.currency) == 0 &&
                                                    !isInt(widget.amountController.text))) {
                                              Scaffold.of(context).showSnackBar(SnackBar(
                                                content: Text('Your Amount is invalid. Please Check again'),
                                                duration: Duration(seconds: 3),
                                              ));
                                              return;
                                            }
                                            widget.item.amount = num.parse(widget.amountController.text);
                                            widget.item.content = widget.contentController.text;
                                            Navigator.pop(context, widget.item);
                                          },
                                          title: Text("Save Changes",
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
    );
  }
}