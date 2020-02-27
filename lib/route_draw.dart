import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';

import 'package:route_draw_for_strava/activity_info.dart';
import 'package:route_draw_for_strava/map_utils.dart';
import 'package:route_draw_for_strava/map_widgets.dart';

class RouteDrawWidget extends StatefulWidget {
  @override
  _RouteDrawWidgetState createState() => _RouteDrawWidgetState();
}

class _RouteDrawWidgetState extends State<RouteDrawWidget> {
  List<Polyline> _polylines;

  @override
  void initState() {
    super.initState();
  }

  void _toActivityInfo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              ActivityInfoWidget(MapUtils.polylinesToLatLngs(_polylines))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Route Draw"),
          actions: <Widget>[
            IconButton(
                icon: const Icon(Icons.check),
                tooltip: 'Next page',
                onPressed: () => _toActivityInfo(context))
          ],
        ),
        body: Stack(children: <Widget>[
          MapWidgets(onPolylinesChanged: (newPolylines) {
            _polylines = newPolylines;
          }),
          _completeDrawWidget(context),
        ]));
  }

  Widget _completeDrawWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: FloatingActionButton(
          onPressed: () => _toActivityInfo(context),
          materialTapTargetSize: MaterialTapTargetSize.padded,
          backgroundColor: Colors.deepOrange,
          child: const Icon(Icons.check, size: 36.0),
        ),
      ),
    );
  }
}
