import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';

import 'package:route_draw_for_strava/activity_info.dart';
import 'package:route_draw_for_strava/map_utils.dart';
import 'package:route_draw_for_strava/map_widgets.dart';
import 'package:route_draw_for_strava/utility_widgets.dart';

class RouteDrawWidget extends StatefulWidget {
  final MapArguments _mapArgs;
  RouteDrawWidget(this._mapArgs);

  @override
  _RouteDrawWidgetState createState() => _RouteDrawWidgetState(_mapArgs);
}

class _RouteDrawWidgetState extends State<RouteDrawWidget> {
  List<Polyline> _polylines = [];
  MapArguments _mapArgs;

  _RouteDrawWidgetState(this._mapArgs);

  @override
  void initState() {
    super.initState();
    _polylines = _mapArgs.polylines;
  }

  void _toActivityInfo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              ActivityInfoWidget(MapUtils.polylinesToLatLngs(_polylines))),
    );
  }

  void _saveRoute() {
    if (_polylines.length < 1) {
      showPopupText(context, "Invalid Arguments",
          "What kind of route just has a starting point?");
      return;
    }
    createAlertDialog(context, "Enter Route Name").then((String routeName) {
      print(routeName);
      if (routeName == null) {
        print("save canceled");
        return;
      } else {
        var storage = RouteStorage(routeName, _polylines);
        storage.writeRouteJSON().then((file) {
          //print(file.path);
          print(file.readAsStringSync());
          //RouteStorage.readRouteFromFilepath(file.path, MapArguments()).then((args)=>print(args.distanceInKm.toString() + " " + MapUtils.calcTotalDistance(MapUtils.polylinesToLatLngs(args.polylines)).toString()));
        });
      }
      RouteStorage.getRoutePaths().then((List<String> lst) => print(lst));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Route Draw"),
          actions: <Widget>[
            IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save Route',
                onPressed: _saveRoute),
            IconButton(
                icon: const Icon(Icons.check),
                tooltip: 'Next page',
                onPressed: () => _toActivityInfo(context))
          ],
        ),
        body: Stack(children: <Widget>[
          MapWidgets(_mapArgs, onPolylinesChanged: (newPolylines) {
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
