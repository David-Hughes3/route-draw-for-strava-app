import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:route_draw_for_strava/strava_wrapper.dart';
import 'package:route_draw_for_strava/utility_widgets.dart';

class SettingsWidget extends StatefulWidget {
  @override
  _SettingsWidgetState createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  final _strava = StravaWrapper();
  bool _isAuth;

  @override
  void initState() {
    super.initState();
    _strava.isAuthorized().then((bool result) {
      setState(() {
        _isAuth = result;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuth == null) {
      return new Container();
    } else
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
              flex: 1,
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Text('Manage Strava',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24.0,
                        fontFamily: 'Roboto',
                      )))),
          Visibility(
              visible: !_isAuth,
              child: Expanded(
                  flex: 1,
                  child: FlatButton(
                    key: Key('authorizeButton'),
                    child: Image.asset(
                        "assets/btn_strava_connectwith_orange@2x.png",
                        width: MediaQuery.of(context).size.width / 3 * 2),
                    padding: EdgeInsets.all(0.0),
                    onPressed: () async {
                      await _strava.authorize();
                      await _updateButton();
                    },
                  ))),
          Visibility(
              visible: _isAuth,
              child: Expanded(
                flex: 1,
                child: Center(
                    child: RaisedButton(
                  key: Key('deauthorizeButton'),
                  padding: EdgeInsets.all(20.0),
                  textColor: Colors.white,
                  color: Colors.red[800],
                  child: Text('Deauthorize'),
                  onPressed: () async {
                    await _strava.deauthorize();
                    await _updateButton();
                  },
                )),
              )),
          Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.bottomCenter,
                child:
                    Image.asset("assets/api_logo_pwrdBy_strava_horiz_gray.png"),
              )),
        ],
      );
  }

  void _updateButton() async {
    var isAuth = await _strava.isAuthorized();
    setState(() {
      _isAuth = isAuth;
    });
  }
}
