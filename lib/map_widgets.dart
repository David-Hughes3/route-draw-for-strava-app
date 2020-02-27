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
  LatLng initialCenter = LatLng(34.056234, -117.82057);
  double initialZoom = 15.0;
  double distanceInKm = 0.0; //always stored as KM
  List<Marker> markers = [];
  List<Polyline> polylines = [];
  double markerWidth = 8.0;
  double markerHeight = 8.0;
  String beginningMarkerPath = 'assets/green_circle.png';
  String middleMarkerPath = 'assets/blue_circle.png';
  String endMarkerPath = 'assets/red_circle.png';
}

class MapWidgets extends StatefulWidget {
  final ValueChanged<List<Polyline>> onPolylinesChanged;
  MapArguments mapArgs;

  MapWidgets(this.mapArgs, {this.onPolylinesChanged});

  @override
  _MapWidgetsState createState() => _MapWidgetsState(mapArgs);
}

class _MapWidgetsState extends State<MapWidgets> {
  _MapWidgetsState(this.args);
  MapArguments args;

  ///vars initialized by MapArguments
  LatLng _initialCenter;
  double _initialZoom;
  double _distance;
  List<Marker> _markers;
  List<Polyline> _polylines;
  double _markerWidth;
  double _markerHeight;
  String _beginningMarkerPath;
  String _middleMarkerPath;
  String _endMarkerPath;

  ///Variables always defaulted to empty
  List<Marker> _markerHistory = [];
  List<Polyline> _polylineHistory = [];

  ///Variables setup by init state
  MapController _mapController;
  String _units;
  _navType _curNavType;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _units = MapUtils.getUnitsAsString();
    _curNavType = _navType.LINE;

    _initialCenter = args.initialCenter;
    _initialZoom = args.initialZoom;
    if (MapUtils.getUnits() == Units.MI)
      _distance = MapUtils.kilometersToMiles(args.distanceInKm);
    else
      _distance = args.distanceInKm;
    _markers = args.markers;
    _polylines = args.polylines;
    _markerWidth = args.markerWidth;
    _markerHeight = args.markerHeight;
    _beginningMarkerPath = args.beginningMarkerPath;
    _middleMarkerPath = args.middleMarkerPath;
    _endMarkerPath = args.endMarkerPath;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: _initialCenter,
          zoom: _initialZoom,
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
