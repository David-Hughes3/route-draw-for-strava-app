import 'package:flutter/material.dart';

import 'package:auto_size_text/auto_size_text.dart';

import 'package:route_draw_for_strava/strava_wrapper.dart';
import 'package:route_draw_for_strava/map_utils.dart';

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
                        fontSize: 32.0,
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
                      _updateButton();
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
                  child: AutoSizeText('Deauthorize',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                        fontFamily: 'Roboto',
                      )),
                  onPressed: () async {
                    await _strava.deauthorize();
                    _updateButton();
                  },
                )),
              )),
          Expanded(
              flex: 1,
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Text('Select Units',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28.0,
                        fontFamily: 'Roboto',
                      )))),
          Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.topCenter,
                child: _unitsSelectionWidgets(context),
              )),
          Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Image.asset(
                  "assets/mapbox-logo-black.png",
                  height: MediaQuery.of(context).size.height * 0.05,
                ),
              )),
          Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Image.asset(
                  "assets/api_logo_pwrdBy_strava_horiz_gray.png",
                  height: MediaQuery.of(context).size.height * 0.1,
                ),
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

  void _updateUnits(Units input) {
    setState(() {
      MapUtils.setUnits(input);
    });
  }

  Widget _unitsSelectionWidgets(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            height: MediaQuery.of(context).size.height * 0.05,
            child: RaisedButton(
              elevation: 5.0,
              onPressed: () => _updateUnits(Units.KM),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(0.0))),
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.only(),
                  child: Text('KM'),
                ),
              ),
              color: [
                Colors.grey[300],
                Colors.white
              ][MapUtils.getUnits().index],
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.05,
            child: RaisedButton(
              elevation: 5.0,
              onPressed: () => _updateUnits(Units.MI),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(0.0))),
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.only(),
                  child: Text('MI'),
                ),
              ),
              color: [
                Colors.white,
                Colors.grey[300],
              ][MapUtils.getUnits().index],
            ),
          ),
        ],
      ),
    );
  }
}
