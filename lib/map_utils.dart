import 'dart:math';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:route_draw_for_strava/map_box_request.dart';

import 'map_widgets.dart';

import 'dart:async' show Future;

enum Units { KM, MI }

class MapUtils {
  static MapUtils _instance;
  factory MapUtils() => _instance ??= new MapUtils._();
  MapUtils._();

  static Units _whichUnit = Units.MI;

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
  static double _calcDistance(LatLng point1, LatLng point2) {
    Distance distance = new DistanceVincenty(roundResult: false);
    return distance.as(LengthUnit.Kilometer, point1, point2);
  }

  //in Kilometers
  static double _calcTotalDistance(List<LatLng> input) {
    double total = 0.0;
    for (int i = 0; i < input.length - 1; i++) {
      total += _calcDistance(input[i], input[i + 1]);
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
    DateTime startDateTimeInUtc = start.toUtc();

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
      distancePerSegment.add(_calcDistance(coords[i], coords[i + 1]));
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
      var newTime = df.format(
          startDateTimeInUtc.add(new Duration(seconds: timePerSegmentCDF[i])));
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
  String _routeName;
  String _filename;
  List<Polyline> _polylines;
  double _distanceInKm;
  LatLng _initialCenter;
  String _startAddress;
  String _endAddress = "None";

  RouteStorage(routeName, polylines) {
    _routeName = routeName;
    _filename = routeName + ".json";
    _polylines = polylines;

    _distanceInKm =
        MapUtils._calcTotalDistance(MapUtils.polylinesToLatLngs(_polylines));
    _initialCenter = _polylines[0].points[0];
  }

  static Future<String> get _getLocalDirPath async {
    String dir = (await getApplicationDocumentsDirectory()).path;

    var folder = Directory('$dir/saved_routes/');

    if (await folder.exists()) {
      //if folder already exists return path
      return folder.path;
    } else {
      //if folder not exists create folder and then return its path
      var newFolder = await folder.create(recursive: true);
      return newFolder.path;
    }
  }

  Future<File> get _localFile async {
    final filePath = await _getLocalDirPath;
    return File(filePath + _filename);
  }

  static Future<SavedMapArguments> readRouteFromFilepath(
      String path, SavedMapArguments mapArgs) async {
    try {
      final file = File(path);

      // Read the file
      String contents = await file.readAsString();

      Map json = jsonDecode(contents);

      List<List<double>> temp3 = [];
      json['polylinesLats']
          .forEach((x) => temp3.add(x.cast<double>().toList()));

      String _routeName = json['routeName'] as String;
      String _startAddress = json['startAddress'] as String;
      String _endAddress = json['endAddress'] as String;
      double _distanceInKm = json['distanceInKm'] as double;
      double _initialCenterLat = json['initialCenterLat'] as double;
      double _initialCenterLng = json['initialCenterLng'] as double;
      List<List<double>> _polylineLats = [];
      json['polylinesLats']
          .forEach((x) => _polylineLats.add(x.cast<double>().toList()));
      List<List<double>> _polylineLngs = [];
      json['polylinesLngs']
          .forEach((x) => _polylineLngs.add(x.cast<double>().toList()));

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

      mapArgs.routeName = _routeName;
      mapArgs.startAddress = _startAddress;
      mapArgs.endAddress = _endAddress;

      mapArgs.initialCenter = center;
      mapArgs.polylines = polylines;
      mapArgs.markers = markers;
      mapArgs.distanceInKm = _distanceInKm;

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

    _startAddress = await MapBoxRequest.makeLocationRequest(
        _initialCenter, FeatureType.NEIGHBORHOOD);

    var toEncode = _routeJSON(
        _routeName,
        _startAddress,
        _endAddress,
        _distanceInKm,
        _initialCenter.latitude,
        _initialCenter.longitude,
        polylineLats,
        polylineLngs);

    String jsonString = jsonEncode(toEncode);

    // Write the file
    return file.writeAsString(jsonString);
  }

  static Future<List<String>> getRoutePaths() async {
    final dirPath = await _getLocalDirPath;
    List<String> paths = [];

    var fileList =
        Directory(dirPath).listSync(recursive: true, followLinks: false);

    fileList.forEach((FileSystemEntity f) => paths.add(f.path));

    return paths;
  }

  static deleteRoutes() async {
    final dirPath = await _getLocalDirPath;

    var fileList =
        Directory(dirPath).listSync(recursive: true, followLinks: false);
    print("filelist (before) = " + fileList.toString());

    fileList.forEach((FileSystemEntity f) => f.deleteSync(recursive: false));

    fileList = Directory(dirPath).listSync(recursive: true, followLinks: false);
    print("filelist (after) = " + fileList.toString());
  }
}

class _routeJSON {
  final String _routeName;
  final String _startAddress;
  final String _endAddress;
  final double _distanceInKm;
  final double _initialCenterLat;
  final double _initialCenterLng;
  final List<List<double>> _polylineLats;
  final List<List<double>> _polylineLngs;

  _routeJSON(
      this._routeName,
      this._startAddress,
      this._endAddress,
      this._distanceInKm,
      this._initialCenterLat,
      this._initialCenterLng,
      this._polylineLats,
      this._polylineLngs);

  Map<String, dynamic> toJson() => {
        'routeName': this._routeName,
        'startAddress': this._startAddress,
        'endAddress': this._endAddress,
        'distanceInKm': this._distanceInKm,
        'initialCenterLat': this._initialCenterLat,
        'initialCenterLng': this._initialCenterLng,
        'polylinesLats': this._polylineLats,
        'polylinesLngs': this._polylineLngs,
      };
}
