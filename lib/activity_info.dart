import 'package:flutter/material.dart';

import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:route_draw_for_strava/upload_activity.dart';
import 'map_utils.dart';

class ActivityInfoWidget extends StatefulWidget {
  ActivityInfoWidget(this.coords);
  final List<LatLng> coords;
  @override
  _ActivityInfoState createState() => _ActivityInfoState(coords);
}

class _ActivityInfoState extends State<ActivityInfoWidget> {

  _ActivityInfoState(this._coords);
  final List<LatLng> _coords;
  double _distance ;


  @override
  void initState(){
    super.initState();
    _distance = MapUtils.calcTotalDistance(_coords);
  }


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
            'Upload Activity Distance ${_distance.toStringAsFixed(2)}'
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
