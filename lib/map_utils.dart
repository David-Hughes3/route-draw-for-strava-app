import 'dart:math';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/route.gpx');
  }

//  Future<File> toGPXFile(List<LatLng> coords) async {
//    String name = 'Example';
//
//    String header = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?><gpx xmlns=\"http://www.topografix.com/GPX/1/1\" creator=\"MapSource 6.15.5\" version=\"1.1\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"  xsi:schemaLocation=\"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd\"><trk>\n";
//    name = "<name>" + name + "</name><trkseg>\n";
//
//    String segments = "";
//    DateFormat df = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ");
//    for (Location location : points) {
//      segments += "<trkpt lat=\"" + location.getLatitude() + "\" lon=\"" + location.getLongitude() + "\"><time>" + df.format(new Date(location.getTime())) + "</time></trkpt>\n";
//    }
//
//    String footer = "</trkseg></trk></gpx>";
//
//
//
//    final file = await _localFile;
//    // Write the file.
//    return file.writeAsString('$counter');
//  }
}
