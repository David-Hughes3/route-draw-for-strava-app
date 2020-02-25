import 'package:flutter/material.dart';

import 'package:strava_flutter/Models/fault.dart';

import 'package:route_draw_for_strava/strava_wrapper.dart';
import 'package:route_draw_for_strava/map_utils.dart';

class UploadActivityWidget extends StatefulWidget {
  UploadActivityWidget(this._name, this._desc, this._gpxFilePath);
  final String _name;
  final String _desc;
  final String _gpxFilePath;

  @override
  _UploadActivityState createState() =>
      _UploadActivityState(_name, _desc, _gpxFilePath);
}

class _UploadActivityState extends State<UploadActivityWidget> {
  _UploadActivityState(this._name, this._desc, this._gpxFilePath);
  final String _name;
  final String _desc;
  final String _gpxFilePath;

  String _status = 'Uploading...';

  @override
  void initState() {
    super.initState();
    GPXStorage().readRouteGPX().then((String file) => print(file));
    StravaWrapper _strava = StravaWrapper();
    _strava
        .uploadActivity(_name, _desc, _gpxFilePath)
        .then((Fault fault) => setState(() => _status += fault.message));
  }

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
              child: Text('Status: $_status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 32.0,
                    fontFamily: 'Roboto',
                  )),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  onPressed: () => Navigator.popUntil(
                      context, ModalRoute.withName(Navigator.defaultRouteName)),
                  tooltip: 'BackToHome',
                  child: Icon(Icons.home),
                ),
              ),
            ),
          ],
        ));
  }
}
