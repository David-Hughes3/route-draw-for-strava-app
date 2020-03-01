import 'package:flutter/material.dart';

import 'package:auto_size_text/auto_size_text.dart';

import 'package:route_draw_for_strava/map_widgets.dart';
import 'package:route_draw_for_strava/utility_widgets.dart';
import 'package:route_draw_for_strava/strava_wrapper.dart';
import 'package:route_draw_for_strava/route_draw.dart';
import 'package:route_draw_for_strava/load_route.dart';

class HomeMenuWidget extends StatelessWidget {
  final _strava = StravaWrapper();
  @override
  Widget build(BuildContext context) {
    var textGroup = AutoSizeGroup();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.08,
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: RaisedButton(
                    key: Key('startNewRoute'),
                    child: AutoSizeText(
                      'Start New',
                      maxLines: 1,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28.0,
                        fontFamily: 'Roboto',
                      ),
                      group: textGroup,
                    ),
                    onPressed: () async => _onPressedToRouteDraw(context),
                    textColor: Colors.black,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(0.0),
                        side: BorderSide(color: Colors.deepOrange)),
                  ),
                ),
              )),
          Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.08,
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: RaisedButton(
                    key: Key('startFromSaved'),
                    child: AutoSizeText(
                      'From Saved',
                      maxLines: 1,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28.0,
                        fontFamily: 'Roboto',
                      ),
                      group: textGroup,
                    ),
                    onPressed: () async => _onPressedToSavedRoutes(context),
                    textColor: Colors.black,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(0.0),
                        side: BorderSide(color: Colors.deepOrange)),
                  ),
                ),
              )),
          Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.bottomCenter,
                child:
                    Image.asset("assets/api_logo_pwrdBy_strava_horiz_gray.png"),
              )),
        ],
      ),
    );
  }

  void _onPressedToRouteDraw(BuildContext context) async {
    var isAuth = await _strava.isAuthorized();

    if (isAuth) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => RouteDrawWidget(MapArguments())),
      );
    } else {
      showPopupText(context, "Strava Not Authorized", "Settings > Authorize");
    }
  }

  void _onPressedToSavedRoutes(BuildContext context) async {
    var isAuth = await _strava.isAuthorized();

    if (isAuth) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoadRouteWidget()),
      );
    } else {
      showPopupText(context, "Strava Not Authorized", "Settings > Authorize");
    }
  }
}
