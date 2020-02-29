import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:latlong/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:route_draw_for_strava/secret.dart';

enum FeatureType { ADDRESS, PLACE, NEIGHBORHOOD }

class MapBoxRequest {
  static Future<List<LatLng>> makeNavigationRequest(
      LatLng start, LatLng end) async {
    ///build GET request
    String profile = "mapbox/walking";
    String coords =
        "${start.longitude}%2C${start.latitude}%3B${end.longitude}%2C${end.latitude}"; //%2C = comma, %3B = ;
    String geometries = "geometries=polyline";
    String accessToken = "access_token=$MAPBOX_API_KEY";

    String url =
        "https://api.mapbox.com/directions/v5/$profile/$coords?$geometries&$accessToken";
    //print("GET REQUEST = " + url);

    ///make request to mapbox navigation api
    final response = await http.get(url);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      String encodedPolyline = jsonResponse['routes'][0]["geometry"] as String;

      //print("Response POLYLINE = " + encodedPolyline);

      ///convert the response google encoded polyline to LatLngs
      List<PointLatLng> result =
          PolylinePoints().decodePolyline(encodedPolyline);
      List<LatLng> output = [];
      result.forEach(
          (PointLatLng p) => output.add(LatLng(p.latitude, p.longitude)));
      return output;
    } else {
      throw Exception("Failed with ${response.statusCode} : ${response.body}");
    }
  }

  static Future<String> makeLocationRequest(
      LatLng point, FeatureType featureType) async {
    ///build GET request
    String endpoint = "mapbox.places";
    String coords = "${point.longitude}%2C${point.latitude}"; //%2C = comma
    String accessToken = "access_token=$MAPBOX_API_KEY";
    String types;
    if (featureType == FeatureType.ADDRESS)
      types = "address";
    else if (featureType == FeatureType.PLACE)
      types = "place";
    else if (featureType == FeatureType.NEIGHBORHOOD) types = "neighborhood";

    String url =
        "https://api.mapbox.com/geocoding/v5/$endpoint/$coords.json?types=$types&$accessToken";
    //print("GET REQUEST = " + url);

    ///make request to mapbox navigation api
    final response = await http.get(url);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      var features = jsonResponse['features'];

      String address = "";
      for (var feature in features) {
        if (feature["place_type"][0] as String == types)
          address = feature["place_name"] as String;
      }

      //print("location text = " + address);
      return address;
    } else {
      throw Exception("Failed with ${response.statusCode} : ${response.body}");
    }
  }
}
