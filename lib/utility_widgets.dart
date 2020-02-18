import 'package:flutter/material.dart';

class PlaceholderWidget extends StatelessWidget {
  final Color color;

  PlaceholderWidget(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
    );
  }
}

void showPopupText(
    BuildContext contextArg, String titleString, String contentString) {
  // flutter defined function
  showDialog(
    context: contextArg,
    builder: (BuildContext context) {
      // return object of type Dialog
      return new AlertDialog(
        title: new Text(titleString),
        content: new Text(contentString),
        actions: <Widget>[
          // usually buttons at the bottom of the dialog
          new FlatButton(
            child: new Text("Close"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
