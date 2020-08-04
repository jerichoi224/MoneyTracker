import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import 'database_helpers.dart';

class EditWidget extends StatefulWidget {
  final contentController = TextEditingController();
  final amountController = TextEditingController();
  final SingleEntry item;

  EditWidget({Key key, this.item}) : super(key: key);

  @override
  State createState() => _EditState();
}

class _EditState extends State<EditWidget> {
  NumberFormat moneyNf = NumberFormat.simpleCurrency(decimalDigits: 2);

  // Check if the value is numeric
  bool isNumeric(String s) {
    if (s == null) {
      return false;
    }
    return double.tryParse(s) != null;
  }

  @override
  Widget build(BuildContext context) {
    widget.amountController.text = widget.item.amount.toString();
    widget.contentController.text = widget.item.content == "No Description" ? "" : widget.item.content.toString();
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
                                color: Color.fromRGBO(149, 213, 178, 1),
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      ListTile(
                                          onTap:(){
                                            // Invalid input
                                            if(!isNumeric(widget.amountController.text)) {
                                              Scaffold.of(context).showSnackBar(SnackBar(
                                                content: Text('Your Amount is invalid. Please Check again'),
                                                duration: Duration(seconds: 3),
                                              ));
                                              return;
                                            }
                                            widget.item.amount = double.parse(widget.amountController.text);
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