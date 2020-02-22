import 'package:flutter/material.dart';

import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';

import 'package:route_draw_for_strava/upload_activity.dart';

class ActivityInfoWidget extends StatefulWidget {
  ActivityInfoWidget(this.distance);
  final double distance;
  @override
  _ActivityInfoState createState() => _ActivityInfoState(distance);
}

class _ActivityInfoState extends State<ActivityInfoWidget> {

  _ActivityInfoState(this._distance);
  final double _distance;

  void _toUploadActivity(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UploadActivityWidget()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text("Route Draw for Strava"),
        ),
        body: Stack(children: <Widget>[
          Text(
            'Upload Activity Distance $_distance'
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                onPressed: () => _toUploadActivity(context),
                tooltip: 'UploadActivity',
                child: Icon(Icons.check),
              ),
            ),
          ),
        ]));
  }
}
