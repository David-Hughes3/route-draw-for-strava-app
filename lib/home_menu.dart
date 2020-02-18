import 'package:flutter/material.dart';
import 'package:route_draw_for_strava/utility_widgets.dart';
import 'package:route_draw_for_strava/strava_wrapper.dart';
import 'package:route_draw_for_strava/route_draw.dart';

class HomeMenuWidget extends StatelessWidget {
  final _strava = StravaWrapper();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
              flex: 2,
              child: Center(
                  child: RaisedButton(
                key: Key('startNewRoute'),
                child: Text('Start New'),
                onPressed: () async => _onPressed(context),
                textColor: Colors.black,
                color: Colors.white,
                padding: EdgeInsets.all(20.0),
                shape: RoundedRectangleBorder(
                    borderRadius: new BorderRadius.circular(0.0),
                    side: BorderSide(color: Colors.deepOrange)),
              ))),
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

  void _onPressed(BuildContext context) async {
    var isAuth = await _strava.isAuthorized();

    if (isAuth) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RouteDrawWidget()),
      );
    } else {
      showPopupText(context, "Strava Not Authorized", "Settings > Authorize");
    }
  }
}
