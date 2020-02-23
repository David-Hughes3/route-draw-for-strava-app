import 'dart:async';

import 'package:flutter/material.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:geolocator/geolocator.dart';

import 'package:route_draw_for_strava/activity_info.dart';
import 'package:route_draw_for_strava/secret.dart';
import 'package:route_draw_for_strava/map_utils.dart';

//reference to adding pin on press: https://stackoverflow.com/questions/57159415/how-does-drop-pins-with-long-press-on-google-map-with-flutter
//reference to adding marker and polyline: https://stackoverflow.com/questions/53171531/how-to-add-polyline-on-google-maps-flutter-plugin

class RouteDrawWidget extends StatefulWidget {
  @override
  _RouteDrawWidgetState createState() => _RouteDrawWidgetState();
}

enum _navType { WALK, LINE }

class _RouteDrawWidgetState extends State<RouteDrawWidget> {
  final _startLatLng = const LatLng(45.521563, -122.677433);
  GoogleMapController _mapController;
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  GoogleMapPolyline _googleMapPolyline =
      new GoogleMapPolyline(apiKey: GOOGLE_MAPS_API_KEY);

  MapType _currentMapType = MapType.normal;
  var _distance = 0.0;
  var _units = MapUtils.getUnitsAsString();

  var _curNavType = _navType.LINE;
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];

  Future _addMarker(LatLng latlang) async {
    List<LatLng> coords = [];
    if (_markers.length >= 1) {
      LatLng originPoint = _markers.last.position;
      LatLng  destPoint = latlang;

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

      final MarkerId markerId = MarkerId("MARKER_ID_${_markers.length}");
      Marker marker = Marker(
        markerId: markerId,
        draggable: true,
        position: latlang, //automatically obtain latitude and longitude
        icon: BitmapDescriptor.defaultMarker,
      );

      _markers.add(marker);

      if (_markers.length >= 2) {
        _polylines.add(Polyline(
          polylineId: PolylineId("POLYLINE_ID_${_polylines.length}"),
          visible: true,
          points: coords,
          color: Colors.blue,
          width: 4,
        ));
      }

      _distance =  _calcDistance();
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

      //TODO
      _distance =  _calcDistance();
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

      if (_polylines.isNotEmpty) {
        var lastPolyline = _polylines.removeLast();
        _polylineHistory.add(lastPolyline);
      }

      //TODO
      _distance =  _calcDistance();
    });
  }

  void _redoButtonCallback() {
    if (_markerHistory.isEmpty) {
      return;
    }
    setState(() {
      var lastMarker = _markerHistory.removeLast();
      _markers.add(lastMarker);

      if (_polylineHistory.isNotEmpty && _markers.length >= 2) {
        var lastPolyline = _polylineHistory.removeLast();
        _polylines.add(lastPolyline);
      }

      //TODO
      _distance =  _calcDistance();
    });
  }

  void _onLocationSearchingButtonPressed() async {
//    GeolocationStatus geolocationStatus  = await Geolocator().checkGeolocationPermissionStatus();
//    print(geolocationStatus);
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    print(position);

    _mapController.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
          target: LatLng(position.latitude, position.longitude), zoom: 15.0),
    ));
  }

  //TODO
  double _calcDistance() {
    var latlangs = MapUtils.polylinesToLatLngs(_polylines);
    return MapUtils.calcTotalDistance(latlangs);
  }

  void _toActivityInfo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ActivityInfoWidget(MapUtils.polylinesToLatLngs(_polylines))),
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
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _startLatLng,
              zoom: 11.0,
            ),
            mapType: _currentMapType,
            polylines: _polylines.toSet(),
            markers: _markers.toSet(),
            onTap: (latlang) {
              _addMarker(latlang);
            },
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
                  _mapController.moveCamera(
                    CameraUpdate.zoomIn(),
                  );
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
                  _mapController.moveCamera(
                    CameraUpdate.zoomOut(),
                  );
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

  void _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

//          Padding(
//            padding: const EdgeInsets.all(16.0),
//            child: Align(
//              alignment: Alignment.topRight,
//              child: FloatingActionButton(
//                heroTag: "btn1",
//                onPressed: _onMapTypeButtonPressed,
//                materialTapTargetSize: MaterialTapTargetSize.padded,
//                backgroundColor: Colors.deepOrange,
//                child: const Icon(Icons.map, size: 36.0),
//              ),
//            ),
//          ),

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
