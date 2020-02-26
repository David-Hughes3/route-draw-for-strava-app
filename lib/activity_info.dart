import 'package:flutter/material.dart';
import 'dart:io';

import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:latlong/latlong.dart';
import 'package:intl/intl.dart';

import 'package:route_draw_for_strava/upload_activity.dart';
import 'map_utils.dart';
import 'package:route_draw_for_strava/utility_widgets.dart';

class ActivityInfoWidget extends StatefulWidget {
  ActivityInfoWidget(this.coords);
  final List<LatLng> coords;
  @override
  _ActivityInfoState createState() => _ActivityInfoState(coords);
}

class _ActivityInfoState extends State<ActivityInfoWidget> {
  _ActivityInfoState(this._coords);
  final List<LatLng> _coords;
  String _units = MapUtils.getUnitsAsString();
  double _distance;
  TextEditingController _controllerTitle;
  TextEditingController _controllerDesc;
  DateTime _elapsedTime;
  DateTime _startDateTime;

  @override
  void initState() {
    super.initState();
    _distance = MapUtils.calcTotalDistance(_coords);
    _controllerTitle = TextEditingController();
    _controllerDesc = TextEditingController();
    _elapsedTime = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day, 0, 0, 0);
    _startDateTime = DateTime.now();
  }

  void dispose() {
    _controllerTitle.dispose();
    _controllerDesc.dispose();
    super.dispose();
  }

  void _toUploadActivity(BuildContext context) {
    if (_coords.length < 2) {
      showPopupText(context, "Invalid Arguments",
          "What kind of route just has a starting point?");
      return;
    }
    if (_controllerTitle.text == null ||
        _controllerTitle.text == "null" ||
        _controllerTitle.text == "") {
      showPopupText(context, "Invalid Arguments", "Enter A Activity Title");
      return;
    }

    MapUtils.toGPXFile(_coords, _startDateTime, _elapsedTime)
        .then((File gpxFile) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => UploadActivityWidget(
                _controllerTitle.text, _controllerDesc.text, gpxFile.path)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomPadding: false,
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text("Route Draw for Strava"),
        ),
        body: Stack(children: <Widget>[
          Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                    flex: 1,
                    child: Align(
                        alignment: Alignment.center,
                        child: Text('Enter Activity Info',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 32.0,
                              fontFamily: 'Roboto',
                            )))),
                Expanded(
                    flex: 1,
                    child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Text('Activity Title',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24.0,
                              fontFamily: 'Roboto',
                            )))),
                Expanded(
                  flex: 1,
                  child: Align(
                      alignment: Alignment.topCenter,
                      child: Center(
                        child: TextField(
                          controller: _controllerTitle,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Activity Title',
                          ),
                        ),
                      )),
                ),
                Expanded(
                    flex: 1,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Text(
                                'Distance: ${_distance.toStringAsFixed(2)} $_units ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24.0,
                                  fontFamily: 'Roboto',
                                )),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: RaisedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text('Edit'),
                            ),
                          ),
                        )
                      ],
                    )),
                Expanded(
                    flex: 1,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: RaisedButton(
                          onPressed: () {
                            DatePicker.showDateTimePicker(context,
                                showTitleActions: true,
                                minTime: DateTime.now().add(new Duration(
                                    days:
                                        -1825)), //minimum time to scroll to is 5 years ago
                                maxTime: DateTime.now()
                                    .add(new Duration(seconds: 1)),
                                onConfirm: (date) {
                              print('confirm $date');
                              setState(() {
                                _startDateTime = date;
                              });
                            },
                                currentTime: _startDateTime,
                                locale: LocaleType.en);
                          },
                          child: Text(
                            'Start date-time: ${new DateFormat("MM/dd/yy h:mm a").format(_startDateTime)}',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20.0,
                            ),
                          )),
                    )),
                Expanded(
                    flex: 1,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: RaisedButton(
                          onPressed: () {
                            DatePicker.showTimePicker(
                              context,
                              showTitleActions: true,
                              onConfirm: (date) {
                                print('confirm $date');
                                setState(() {
                                  _elapsedTime = date;
                                });
                              },
                              currentTime: _elapsedTime,
                            );
                          },
                          child: Text(
                            'Elapsed Time: ${new DateFormat("HH:mm:ss").format(_elapsedTime)}',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20.0,
                            ),
                          )),
                    )),
                Expanded(
                    flex: 1,
                    child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Text('Description',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24.0,
                              fontFamily: 'Roboto',
                            )))),
                Expanded(
                  flex: 1,
                  child: Align(
                      alignment: Alignment.topCenter,
                      child: Center(
                        child: TextField(
                          controller: _controllerDesc,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Optional',
                          ),
                        ),
                      )),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 0.0, top: 0.0, right: 16.0, bottom: 16.0),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: FloatingActionButton(
                        onPressed: () => _toUploadActivity(context),
                        tooltip: 'UploadActivity',
                        child: Icon(Icons.check),
                      ),
                    ),
                  ),
                ),
              ]),
        ]));
  }
}
