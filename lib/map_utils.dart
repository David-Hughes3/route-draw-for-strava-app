import 'dart:math';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

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
    return km * 0.621371;
  }

  // TODO
  static List<LatLng> polylinesToLatLngs(List<Polyline> input) {
    List<LatLng> output = [];
    if (input.length != 0) {
      output = [input[0].points[0]];
      input.forEach((p) => {
            p.points.forEach((coord) => {
                  if (coord != output.last) {output.add(coord)}
                })
          });
    }

    return output;
  }

  static Future<File> toGPXFile(
      List<LatLng> coords, DateTime start, DateTime elapsed) async {
    //calc the total time
    //datetime picker does not have a duration picker, so the date portion of the passed elapsed is useless/should be ignored
    var endTime = start.add(new Duration(
        hours: elapsed.hour, minutes: elapsed.minute, seconds: elapsed.second));
    var totalTime = endTime.difference(start);

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
    distancePerSegment.forEach((dist) =>
        timePerSegment.add((dist / distanceSum * totalTime.inSeconds).round()));

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
