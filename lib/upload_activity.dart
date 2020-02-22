import 'package:flutter/material.dart';

class UploadActivityWidget extends StatefulWidget {
  @override
  _UploadActivityState createState() => _UploadActivityState();
}

class _UploadActivityState extends State<UploadActivityWidget> {

  var _status = 'uploading';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text("Route Draw for Strava"),
          automaticallyImplyLeading: false,
        ),
        body: Stack(
          children: <Widget>[
            Center(
              child: Text(
                'Status: $_status',
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  onPressed: () => Navigator.popUntil(context, ModalRoute.withName(Navigator.defaultRouteName)),
                  tooltip: 'BackToHome',
                  child: Icon(Icons.home),
                ),
              ),
            ),
          ],
        ));
  }
}
