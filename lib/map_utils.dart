import 'dart:math';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

import 'map_widgets.dart';

enum Units { KM, MI }

class MapUtils {
  static MapUtils _instance;
  factory MapUtils() => _instance ??= new MapUtils._();
  MapUtils._();

  static Units _whichUnit = Units.KM;

  static void setUnits(Units input) {
    _whichUnit = input;
  }

  static Units getUnits() {
    return _whichUnit;
  }

  static String getUnitsAsString() {
    String units = "";
    if (_whichUnit == Units.KM) {
      units = "KM";
    } else if (_whichUnit == Units.MI) {
      units = "MI";
    }
    return units;
  }

  static double calcTotalDistance(List<LatLng> input) {
    double total = _calcTotalDistance(input);
    if (_whichUnit == Units.MI) total = kilometersToMiles(total);
    return total;
  }

  //in Kilometers
  static double _calcDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295; // Math.PI / 180
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;

    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  //in Kilometers
  static double _calcTotalDistance(List<LatLng> input) {
    double total = 0.0;
    for (int i = 0; i < input.length - 1; i++) {
      total += _calcDistance(input[i].latitude, input[i].longitude,
          input[i + 1].latitude, input[i + 1].longitude);
    }
    return total;
  }

  static double kilometersToMiles(double km) {
    return km * 0.62137119;
  }

  static double milesToKilometers(double mi) {
    return mi * 1.609344;
  }

  static List<LatLng> polylinesToLatLngs(List<Polyline> input) {
    List<LatLng> output = [];
    if (input.length != 0) {
      output = [input[0].points[0]];
      input.forEach((p) {
        p.points.forEach((coord) {
          if (coord != output.last) output.add(coord);
        });
      });
    }
    return output;
  }

  static List<LatLng> polylinesToMarkerPoints(List<Polyline> input) {
    List<LatLng> output = [];

    if (input.length != 0) {
      LatLng firstPoint = input[0].points.first;
      output.add(firstPoint);

      input.forEach((poly) => output.add(poly.points.last));
    }
    return output;
  }

  static Future<File> toGPXFile(
      List<LatLng> coords, DateTime start, DateTime elapsed) async {
    //calc the total time
    //datetime picker does not have a duration picker, so the date portion of the passed elapsed is useless/should be ignored
    int totalTime = Duration(
            hours: elapsed.hour,
            minutes: elapsed.minute,
            seconds: elapsed.second)
        .inSeconds;

    //calculate distance per segment and total distance from passed LatLngs
    List<double> distancePerSegment = [];
    for (int i = 0; i < coords.length - 1; i++) {
      distancePerSegment.add(_calcDistance(
          coords[i].latitude,
          coords[i].longitude,
          coords[i + 1].latitude,
          coords[i + 1].longitude));
    }
    double distanceSum = distancePerSegment.fold(
        0, (p, c) => p + c); //sum as in a functional manner

    //ratio of distance per segment times total time = time per segment
    List<int> timePerSegment = [];
    distancePerSegment.forEach(
        (dist) => timePerSegment.add((dist / distanceSum * totalTime).round()));

    //cumulative discrete distribution needs to be used to add time to start
    List<int> timePerSegmentCDF = [0];
    timePerSegment.forEach((time) {
      int cdfI = timePerSegmentCDF.last + time;
      timePerSegmentCDF.add(cdfI);
    });

    //Start formatting gpx file
    String name = 'Example';

    String header =
        "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?><gpx xmlns=\"http://www.topografix.com/GPX/1/1\" creator=\"MapSource 6.15.5\" version=\"1.1\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"  xsi:schemaLocation=\"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd\"><trk>\n";
    name = "<name>" + name + "</name><trkseg>\n";

    String segments = "";
    DateFormat df = new DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
    for (int i = 0; i < coords.length; i++) {
      var newTime =
          df.format(start.add(new Duration(seconds: timePerSegmentCDF[i])));
      segments += "<trkpt lat=\"" +
          coords[i].latitude.toString() +
          "\" lon=\"" +
          coords[i].longitude.toString() +
          "\"><time>" +
          newTime +
          "</time></trkpt>\n";
    }

    String footer = "</trkseg></trk></gpx>";

    //output gpx file
    var gpx = GPXStorage();
    return gpx
        .writeRouteGPX(header + '\n' + name + '\n' + segments + '\n' + footer);
  }
}

class GPXStorage {
  final String _filename = 'route.gpx';

  Future<String> get _getLocalFilePath async {
    String dir = (await getApplicationDocumentsDirectory()).path;

    return '$dir/$_filename';
  }

  Future<File> get _localFile async {
    final filePath = await _getLocalFilePath;
    return File(filePath);
  }

  Future<String> readRouteGPX() async {
    try {
      final file = await _localFile;

      // Read the file
      String contents = await file.readAsString();

      return contents;
    } catch (e) {
      print(e);
      return e;
    }
  }

  Future<File> writeRouteGPX(String outputString) async {
    final file = await _localFile;

    // Write the file
    return file.writeAsString(outputString);
  }
}

class RouteStorage {
  String _filename;
  List<Polyline> _polylines;
  double _distance;
  LatLng _initialCenter;

  RouteStorage(filename, polylines) {
    _filename = filename;
    _polylines = polylines;

    _distance =
        MapUtils.calcTotalDistance(MapUtils.polylinesToLatLngs(_polylines));
    _initialCenter = _polylines[0].points[0];


  }

  Future<String> get _getLocalFilePath async {
    String dir = (await getApplicationDocumentsDirectory()).path;

    var folder = Directory('${dir}/saved_routes/');

    if(await folder.exists()){ //if folder already exists return path
      return folder.path;
    }else{//if folder not exists create folder and then return its path
      var newFolder = await folder.create(recursive: true);
      return newFolder.path;
    }

  }

  Future<File> get _localFile async {
    final filePath = await _getLocalFilePath;
    return File(filePath + _filename);
  }

  static Future<MapArguments> readRouteFromFilepath(
      String path, MapArguments mapArgs) async {
    try {
      final file = File(path);

      // Read the file
      String contents = await file.readAsString();

      Map json = jsonDecode(contents);

      List<List<double>> temp3 = [];
      json['polylinesLats'].forEach((x) => temp3.add(x.cast<double>().toList()) );

      String _name = json['name'] as String;
      double _distance = json['distance'] as double;
      double _initialCenterLat = json['initialCenterLat'] as double;
      double _initialCenterLng = json['initialCenterLng'] as double;
      List<List<double>> _polylineLats = [];
      json['polylinesLats'].forEach((x) => _polylineLats.add(x.cast<double>().toList()) );
      List<List<double>> _polylineLngs = [];
      json['polylinesLngs'].forEach((x) => _polylineLngs.add(x.cast<double>().toList()) );

      LatLng center = LatLng(_initialCenterLat, _initialCenterLng);
      List<Polyline> polylines = [];
      for (int i = 0; i < _polylineLats.length; i++) {
        var lats = _polylineLats[i];
        var lngs = _polylineLngs[i];
        List<LatLng> coords = [];
        for (int i = 0; i < lats.length; i++) {
          coords.add(LatLng(lats[i], lngs[i]));
        }

        Polyline newPolyline = Polyline(
          points: coords,
          color: mapArgs.polylineColor,
          strokeWidth: mapArgs.polylineStrokeWidth,
        );
        polylines.add(newPolyline);
      }

      var markerPoints = MapUtils.polylinesToMarkerPoints(polylines);
      List<Marker> markers = [];
      markerPoints.asMap().forEach((i, point) {
        String imgPath = mapArgs.middleMarkerPath;
        if (i == 0) imgPath = mapArgs.beginningMarkerPath;
        if (i == markerPoints.length - 1) imgPath = mapArgs.endMarkerPath;

        Marker newMarker = Marker(
            width: mapArgs.markerWidth,
            height: mapArgs.markerHeight,
            point: point,
            builder: (ctx) => Container(
                  child: Image(image: AssetImage(imgPath)),
                ));
        markers.add(newMarker);
      });

      mapArgs.initialCenter = center;
      mapArgs.polylines = polylines;
      mapArgs.markers = markers;
      mapArgs.distanceInKm = _distance;

      return mapArgs;
    } catch (e) {
      print(e);
      return e;
    }
  }

  Future<File> writeRouteJSON() async {
    final file = await _localFile;

    List<List<double>> polylineLats = [];
    List<List<double>> polylineLngs = [];

    _polylines.forEach((poly) {
      List<double> lats = [];
      List<double> lngs = [];
      poly.points.forEach((latlng) {
        lats.add(latlng.latitude);
        lngs.add(latlng.longitude);
      });
      polylineLats.add(lats);
      polylineLngs.add(lngs);
    });

    var toEncode = _routeJSON(_filename, _distance, _initialCenter.latitude,
        _initialCenter.longitude, polylineLats, polylineLngs);

    String jsonString = jsonEncode(toEncode);

    // Write the file
    return file.writeAsString(jsonString);
  }
}

class _routeJSON {
  final String _name;
  final double _distance;
  final double _initialCenterLat;
  final double _initialCenterLng;
  final List<List<double>> _polylineLats;
  final List<List<double>> _polylineLngs;

  _routeJSON(this._name, this._distance, this._initialCenterLat,
      this._initialCenterLng, this._polylineLats, this._polylineLngs);

//  _routeJSON.fromJson(Map<String, dynamic> json)
//      : _name = json['name'] as String,
//        _distance = json['distance'] as double,
//        _initialCenterLat = json['initialCenterLat'] as double,
//        _initialCenterLng = json['initialCenterLng'] as double,
//        _polylineLats = json['polylinesLats'].map((x) => x.cast<double>()).toList() as List<List<double>>,
//        _polylineLngs = json['polylinesLngs'].map((x) => x.cast<double>()).toList() as List<List<double>>;

  Map<String, dynamic> toJson() => {
        'name': this._name,
        'distance': this._distance,
        'initialCenterLat': this._initialCenterLat,
        'initialCenterLng': this._initialCenterLng,
        'polylinesLats': this._polylineLats,
        'polylinesLngs': this._polylineLngs,
      };
}
