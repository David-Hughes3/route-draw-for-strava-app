import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'secret.dart';

//https://pub.dev/packages/strava_flutter#-readme-tab-
import 'package:strava_flutter/strava.dart';
import 'package:strava_flutter/Models/detailedAthlete.dart';

class SettingsWidget extends StatefulWidget {
  @override
  _SettingsWidgetState createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {

  void checkAPIAuth() async {
    // Do authentication with the right scope
    final strava = Strava(
        true, // To get display info in API
        secret);

    bool isAuthOk = false;

    isAuthOk = await strava.oauth(clientId, 'activity:write,activity:read_all,profile:read_all,profile:write', secret, 'auto');

    print('---> Authentication result: $isAuthOk');
  }

  void printAthleteName() async {
    final strava = Strava(true, secret);
    bool isAuthOk = false;
    isAuthOk = await strava.oauth(clientId, 'activity:write,activity:read_all,profile:read_all,profile:write', secret, 'auto');

    if (isAuthOk){
      DetailedAthlete _athlete = await strava.getLoggedInAthlete();
      if (_athlete.fault.statusCode != 200) {
        print(
            'Error in getloggedInAthlete ${_athlete.fault.statusCode}  ${_athlete.fault.message}');
      } else {
        print('getLoggedInAthlete ${_athlete.firstname}  ${_athlete.lastname}');
      }
    }
  }

  void deAuthorize() async {
    // need to get authorized before (valid token)
    final strava = Strava(
      true, // to get disply info in API
      secret, // Put your secret key in secret.dart file
    );
    var fault = await strava.deAuthorize();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      // Center is a layout widget. It takes a single child and positions it
      // in the middle of the parent.
      child: Column(
        // Column is also a layout widget. It takes a list of children and
        // arranges them vertically. By default, it sizes itself to fit its
        // children horizontally, and tries to be as tall as its parent.
        //
        // Invoke "debug painting" (press "p" in the console, choose the
        // "Toggle Debug Paint" action from the Flutter Inspector in Android
        // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
        // to see the wireframe for each widget.
        //
        // Column has various properties to control how it sizes itself and
        // how it positions its children. Here we use mainAxisAlignment to
        // center the children vertically; the main axis here is the vertical
        // axis because Columns are vertical (the cross axis would be
        // horizontal).
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Connect To Strava',
          ),
          RaisedButton(
            key: Key('AuthorizeButton'),
            child: Text('Authorize'),
            // onPressed: exampleStrava,
            onPressed: checkAPIAuth,
          ),
          RaisedButton(
            key: Key('PrintNameButton'),
            child: Text('Print Name'),
            // onPressed: exampleStrava,
            onPressed: printAthleteName,
          ),
          RaisedButton(
            key: Key('DeAuthorizeButton'),
            child: Text('DeAuthorize'),
            // onPressed: exampleStrava,
            onPressed: deAuthorize,
          ),
        ],
      ),
    );
  }
}