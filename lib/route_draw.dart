import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';

import 'package:route_draw_for_strava/activity_info.dart';
import 'package:route_draw_for_strava/secret.dart';
import 'package:route_draw_for_strava/map_utils.dart';

import 'dart:ui' as ui;

//reference to adding pin on press: https://stackoverflow.com/questions/57159415/how-does-drop-pins-with-long-press-on-google-map-with-flutter
//reference to adding marker and polyline: https://stackoverflow.com/questions/53171531/how-to-add-polyline-on-google-maps-flutter-plugin

class RouteDrawWidget extends StatefulWidget {
  @override
  _RouteDrawWidgetState createState() => _RouteDrawWidgetState();
}

enum _navType { WALK, LINE }
enum _routePointType { BEGINNING, MIDDLE, END }

class _RouteDrawWidgetState extends State<RouteDrawWidget> {
  MapController _mapController;
  double rotation = 0.0;

  String _blueCirclePath = 'assets/blue_circle.png';
  String _greenCirclePath = 'assets/green_circle.png';
  String _redCirclePath = 'assets/red_circle.png';
  double _markerWidth = 8.0;
  double _markerHeight = 8.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  double _distance = 0.0;
  var _units = MapUtils.getUnitsAsString();

  var _curNavType = _navType.LINE;
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];

  Future _addMarker(LatLng latlng) async {
    List<LatLng> coords = [];
    if (_markers.length >= 1) {
      LatLng originPoint = _markers.last.point;
      LatLng destPoint = latlng;

      if (_curNavType == _navType.LINE) {
        coords = [originPoint, destPoint];
      } else if (_curNavType == _navType.WALK) {
        //TODO Enable charging on key?
//        coords = await _googleMapPolyline.getCoordinatesWithLocation(
//            origin: originPoint,
//            destination: destPoint,
//            mode: RouteMode.walking);
        //TODO remove
        coords = [originPoint, destPoint];
      }
    }

    setState(() {
      _markerHistory = [];
      _polylineHistory = [];

      if (_markers.length == 0)
        _markers.add(_changeMarkerRoutePointType(
            Marker(width: _markerWidth, height: _markerHeight, point: latlng),
            _routePointType.BEGINNING));
      else
        _markers.add(_changeMarkerRoutePointType(
            Marker(width: _markerWidth, height: _markerHeight, point: latlng),
            _routePointType.END));

      if (_markers.length >= 2) {
        _markers = List.generate(_markers.length, (i) {
          if (i == 0 || i == _markers.length - 1) {
            return _markers[i];
          } else
            return _changeMarkerRoutePointType(
                _markers[i], _routePointType.MIDDLE);
        });

        _polylines.add(Polyline(
          points: coords,
          color: Colors.blue,
          strokeWidth: 2.0,
        ));
      }

      _distance = _calcDistance();
    });
  }

  void _clearButtonCallback() {
    if (_markers.isEmpty) {
      return;
    }
    setState(() {
      _markerHistory = _markers.reversed.toList();
      _markers = [];

      if (_polylines.isNotEmpty) {
        _polylineHistory = _polylines.reversed.toList();
        _polylines = [];
      }

      _distance = _calcDistance();
    });
  }

  List<Marker> _markerHistory = [];
  List<Polyline> _polylineHistory = [];
  void _undoButtonCallback() {
    if (_markers.isEmpty) {
      return;
    }
    setState(() {
      var lastMarker = _markers.removeLast();
      _markerHistory.add(lastMarker);

      if (_markers.length >= 2)
        _markers.last =
            _changeMarkerRoutePointType(_markers.last, _routePointType.END);

      if (_polylines.isNotEmpty) {
        var lastPolyline = _polylines.removeLast();
        _polylineHistory.add(lastPolyline);
      }

      _distance = _calcDistance();
    });
  }

  void _redoButtonCallback() {
    if (_markerHistory.isEmpty) {
      return;
    }
    setState(() {
      if (_markers.length >= 2)
        _markers.last =
            _changeMarkerRoutePointType(_markers.last, _routePointType.MIDDLE);

      var lastMarker = _markerHistory.removeLast();

      if (_markers.length == 0)
        _markers.add(
            _changeMarkerRoutePointType(lastMarker, _routePointType.BEGINNING));
      else
        _markers
            .add(_changeMarkerRoutePointType(lastMarker, _routePointType.END));

      if (_polylineHistory.isNotEmpty && _markers.length >= 2) {
        var lastPolyline = _polylineHistory.removeLast();
        _polylines.add(lastPolyline);
      }

      _distance = _calcDistance();
    });
  }

  Marker _changeMarkerRoutePointType(Marker inMarker, _routePointType type) {
    String circlePath;
    if (type == _routePointType.BEGINNING)
      circlePath = _greenCirclePath;
    else if (type == _routePointType.MIDDLE)
      circlePath = _blueCirclePath;
    else if (type == _routePointType.END) circlePath = _redCirclePath;

    return Marker(
        width: inMarker.width,
        height: inMarker.height,
        point: inMarker.point,
        builder: (ctx) => Container(
              child: Image(image: AssetImage(circlePath)),
            ));
  }

  void _onLocationSearchingButtonPressed() async {
//    GeolocationStatus geolocationStatus  = await Geolocator().checkGeolocationPermissionStatus();
//    print(geolocationStatus);
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    print(position);

    _mapController.move(LatLng(position.latitude, position.longitude), 15);
  }

  double _calcDistance() {
    var latlangs = MapUtils.polylinesToLatLngs(_polylines);
    return MapUtils.calcTotalDistance(latlangs);
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
          new FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: LatLng(51.5, -0.09),
              zoom: 13.0,
              onTap: _addMarker,
            ),
            layers: [
              TileLayerOptions(
                urlTemplate: "https://api.tiles.mapbox.com/v4/"
                    "{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
                additionalOptions: {
                  'accessToken': MAPBOX_API_KEY,
                  'id': 'mapbox.streets',
                },
              ),
              MarkerLayerOptions(markers: _markers),
              PolylineLayerOptions(polylines: _polylines),
            ],
          ),
          _navSelectionWidgets(context),
          _distanceDisplayWidget(context),
          _undoWidgets(context),
          _zoomWidgets(context),
          _completeDrawWidget(context),
        ]));
  }

  void _updateNavType(newNavType) {
    if (_curNavType != newNavType) {
      setState(() {
        _curNavType = newNavType;
      });
    }
  }

  Widget _navSelectionWidgets(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            height: MediaQuery.of(context).size.height * 0.05,
            child: RaisedButton(
              elevation: 5.0,
              onPressed: () => _updateNavType(_navType.WALK),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(0.0))),
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.only(),
                  child: Icon(Icons.directions_walk, color: Colors.black),
                ),
              ),
              color: [Colors.grey[300], Colors.white][_curNavType.index],
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.05,
            child: RaisedButton(
              elevation: 5.0,
              onPressed: () => _updateNavType(_navType.LINE),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(0.0))),
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.only(),
                  child: Icon(Icons.linear_scale, color: Colors.black),
                ),
              ),
              color: [
                Colors.white,
                Colors.grey[300],
              ][_curNavType.index],
            ),
          ),
        ],
      ),
    );
  }

  Widget _distanceDisplayWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Align(
          alignment: Alignment.bottomRight,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '${_distance.toStringAsFixed(2)} $_units',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 32.0,
                ),
              ),
            ),
          )),
    );
  }

  Widget _locationFinderWidget(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Align(
            alignment: Alignment.topLeft,
            child: RaisedButton(
              onPressed: _onLocationSearchingButtonPressed,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(0.0))),
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.only(),
                  child: Icon(Icons.location_searching, color: Colors.black),
                ),
              ),
            )));
  }

  Widget _zoomWidgets(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(children: <Widget>[
            Container(
              height: MediaQuery.of(context).size.height * 0.05,
              child: RaisedButton(
                elevation: 0.0,
                onPressed: _onLocationSearchingButtonPressed,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(0.0))),
                child: Container(
                  child: Padding(
                    padding: const EdgeInsets.only(),
                    child: Icon(Icons.my_location, color: Colors.black),
                  ),
                ),
                color: Colors.transparent,
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height * 0.05,
              child: RaisedButton(
                elevation: 0.0,
                onPressed: () {
                  _mapController.move(
                      _mapController.center, _mapController.zoom + 1);
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(0.0))),
                child: Container(
                  child: Padding(
                    padding: const EdgeInsets.only(),
                    child: Icon(Icons.zoom_in, color: Colors.black),
                  ),
                ),
                color: Colors.transparent,
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height * 0.05,
              child: RaisedButton(
                elevation: 0.0,
                onPressed: () {
                  _mapController.move(
                      _mapController.center, _mapController.zoom - 1);
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(0.0))),
                child: Container(
                  child: Padding(
                    padding: const EdgeInsets.only(),
                    child: Icon(Icons.zoom_out, color: Colors.black),
                  ),
                ),
                color: Colors.transparent,
              ),
            ),
          ])),
    );
  }

  Widget _undoWidgets(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
          child: Stack(children: <Widget>[
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              height: MediaQuery.of(context).size.height * 0.05,
              child: RaisedButton(
                elevation: 0.0,
                onPressed: _clearButtonCallback,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(0.0))),
                child: Container(
                  child: Padding(
                    padding: const EdgeInsets.only(),
                    child: Icon(Icons.clear, color: Colors.black),
                  ),
                ),
                color: Colors.transparent,
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height * 0.05,
              child: RaisedButton(
                elevation: 0.0,
                onPressed: _redoButtonCallback,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(0.0))),
                child: Container(
                  child: Padding(
                    padding: const EdgeInsets.only(),
                    child: Icon(Icons.redo, color: Colors.black),
                  ),
                ),
                color: Colors.transparent,
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height * 0.05,
              child: RaisedButton(
                elevation: 0.0,
                onPressed: _undoButtonCallback,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(0.0))),
                child: Container(
                  child: Padding(
                    padding: const EdgeInsets.only(),
                    child: Icon(Icons.undo, color: Colors.black),
                  ),
                ),
                color: Colors.transparent,
              ),
            ),
          ],
        ),
      ])),
    );
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
