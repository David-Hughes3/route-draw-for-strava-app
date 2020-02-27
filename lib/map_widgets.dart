import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';

import 'package:route_draw_for_strava/secret.dart';
import 'package:route_draw_for_strava/map_utils.dart';

enum _navType { WALK, LINE }
enum _routePointType { BEGINNING, MIDDLE, END }

class MapArguments {
  String middlePoint = 'assets/blue_circle.png';
  String beginningPoint = 'assets/green_circle.png';
  String endPoint = 'assets/red_circle.png';
  double markerWidth = 8.0;
  double markerHeight = 8.0;
}

class MapWidgets extends StatefulWidget {
  final ValueChanged<List<Polyline>> onPolylinesChanged;

  MapWidgets({this.onPolylinesChanged});

  @override
  _MapWidgetsState createState() => _MapWidgetsState();
}

class _MapWidgetsState extends State<MapWidgets> {
  MapController _mapController;
  double _distance;
  String _units;
  List<Marker> _markers;
  List<Polyline> _polylines;
  _navType _curNavType;
  double _markerWidth;
  double _markerHeight;
  String _beginningMarkerPath;
  String _middleMarkerPath;
  String _endMarkerPath;

  List<Marker> _markerHistory = [];
  List<Polyline> _polylineHistory = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _distance = 0.0;
    _units = MapUtils.getUnitsAsString();
    _markers = [];
    _polylines = [];
    _curNavType = _navType.LINE;
    _markerWidth = 8.0;
    _markerHeight = 8.0;
    _beginningMarkerPath = 'assets/green_circle.png';
    _middleMarkerPath = 'assets/blue_circle.png';
    _endMarkerPath = 'assets/red_circle.png';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      FlutterMap(
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
    ]);
  }

  ///
  /// onTap of flutter_map callback
  ///
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
        widget.onPolylinesChanged(_polylines);
      }

      _distance = _calcDistance();
    });
  }

  Marker _changeMarkerRoutePointType(Marker inMarker, _routePointType type) {
    String markerImagePath;
    if (type == _routePointType.BEGINNING)
      markerImagePath = _beginningMarkerPath;
    else if (type == _routePointType.MIDDLE)
      markerImagePath = _middleMarkerPath;
    else if (type == _routePointType.END) markerImagePath = _endMarkerPath;

    return Marker(
        width: inMarker.width,
        height: inMarker.height,
        point: inMarker.point,
        builder: (ctx) => Container(
              child: Image(image: AssetImage(markerImagePath)),
            ));
  }

  double _calcDistance() {
    var latlangs = MapUtils.polylinesToLatLngs(_polylines);
    return MapUtils.calcTotalDistance(latlangs);
  }

  ///
  /// Navigation Widgets
  /// Two Buttons: walk navigation, line segment
  ///
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

  void _updateNavType(newNavType) {
    if (_curNavType != newNavType) {
      setState(() {
        _curNavType = newNavType;
      });
    }
  }

  ///
  /// Distance Display Widget
  /// One Text Box
  ///
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

  ///
  /// Modify mapController widgets
  /// 3 buttons: locationFinder, Zoom In, Zoom out
  ///
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

  void _onLocationSearchingButtonPressed() async {
//    GeolocationStatus geolocationStatus  = await Geolocator().checkGeolocationPermissionStatus();
//    print(geolocationStatus);
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    print(position);

    _mapController.move(LatLng(position.latitude, position.longitude), 15);
  }

  ///
  ///Modify Drawn Path widgets
  ///3 buttons: clear, redo, undo
  ///
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
        widget.onPolylinesChanged(_polylines);
      }

      _distance = _calcDistance();
    });
  }

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
        widget.onPolylinesChanged(_polylines);
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
        widget.onPolylinesChanged(_polylines);
      }

      _distance = _calcDistance();
    });
  }
}
