import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';

import 'package:route_draw_for_strava/activity_info.dart';
import 'package:route_draw_for_strava/map_utils.dart';
import 'package:route_draw_for_strava/map_widgets.dart';
import 'package:route_draw_for_strava/route_draw.dart';
import 'package:route_draw_for_strava/utility_widgets.dart';

class LoadRouteWidget extends StatefulWidget {
  @override
  _LoadRouteWidgetState createState() => _LoadRouteWidgetState();
}

class _LoadRouteWidgetState extends State<LoadRouteWidget> {
  List<String> _routePaths = [];
  List<SavedMapArguments> _allMapArgs = [];
  String _units = MapUtils.getUnitsAsString();

  final List<Color> _colors = [];
  bool altColor = true;

  @override
  void initState() {
    super.initState();
    RouteStorage.getRoutePaths().then((List<String> lst) {
      _routePaths = lst;
      print(_routePaths);
      _routePaths.forEach((path) {
        RouteStorage.readRouteFromFilepath(path, SavedMapArguments())
            .then((mapArgI) {
          setState(() {
            _allMapArgs.add(mapArgI);
            Color newColor;
            if (altColor)
              newColor = Colors.deepOrangeAccent;
            else
              newColor = Colors.deepOrange;
            altColor = !altColor;
            _colors.add(newColor);
          });
        });
      });
    });
  }

  void _toRouteDraw(BuildContext context, MapArguments args) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RouteDrawWidget(args),
        ));
  }
  
  String _processDistance(double distanceInKm) {
    double distance = distanceInKm;
    if(MapUtils.getUnits() == Units.MI)
      distance = MapUtils.kilometersToMiles(distanceInKm);
    
    return '${distance.toStringAsFixed(2)} ${MapUtils.getUnitsAsString()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Load Saved Route"),
        actions: <Widget>[
          IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Delete All',
              onPressed: () {RouteStorage.deleteRoutes(); Navigator.of(context).pop();}),
          IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Next page',
              onPressed: () => _toRouteDraw(context, MapArguments()))
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: _allMapArgs.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.1,
            child: RaisedButton(
              onPressed: () => _toRouteDraw(context, _allMapArgs[index].toMapArguments()),
              color: _colors[index],
              child: Text(
                'Route Name: ${_allMapArgs[index].routeName}\n ${_allMapArgs[index].startAddress}; ${_processDistance(_allMapArgs[index].distanceInKm)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) => const Divider(),
      ),
    );
  }
}
