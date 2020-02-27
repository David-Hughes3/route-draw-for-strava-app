import 'secret.dart';

//https://pub.dev/packages/strava_flutter#-readme-tab-
import 'package:strava_flutter/strava.dart';
import 'package:strava_flutter/Models/detailedAthlete.dart';
// Used by uploadExample
import 'package:strava_flutter/strava.dart';
import 'package:strava_flutter/Models/fault.dart';
import 'package:strava_flutter/Models/stats.dart'; // Test
import 'package:strava_flutter/errorCodes.dart';
import 'package:strava_flutter/errorCodes.dart' as error;

import 'package:strava_flutter/Models/token.dart';
import 'package:strava_flutter/API/Oauth.dart';

import 'package:strava_flutter/globals.dart';

class AccessAuth extends Auth {}

class StravaWrapper {
  Future<bool> isAuthorized() async {
    var isAuth = false;

    final Token tokenStored = await AccessAuth().getStoredToken();
    final String _token = tokenStored.accessToken;

    var isExpired = _isTokenExpired(tokenStored);

    if (!isExpired && _token != "null" && _token != null) {
      isAuth = true;
    }

    return isAuth;
  }

  Future<void> authorize() async {
    // Do authentication with the right scope
    bool isAuthOk = false;

    var _strava = Strava(true, secret);

    isAuthOk = await _strava.oauth(
        clientId,
        'activity:write,activity:read_all,profile:read_all,profile:write',
        secret,
        'auto');

    print('---> Authentication result: $isAuthOk');
  }

  void printAthleteName() async {
    bool isAuthOk = false;
    var _strava = Strava(true, secret);

    isAuthOk = await isAuthorized();

    if (isAuthOk) {
      DetailedAthlete _athlete = await _strava.getLoggedInAthlete();
      if (_athlete.fault.statusCode != 200) {
        print(
            'Error in getloggedInAthlete ${_athlete.fault.statusCode}  ${_athlete.fault.message}');
      } else {
        print('getLoggedInAthlete ${_athlete.firstname}  ${_athlete.lastname}');
      }
    }
  }

  Future<void> deauthorize() async {
    // need to get authorized before (valid token)
    var _strava = Strava(true, secret);

    var fault = await _strava.deAuthorize();
  }

  /// Return true the expiry date is passed
  ///
  /// Otherwise return false
  ///
  /// including when there is no token yet
  bool _isTokenExpired(Token token) {
    // when it is the first run or after a deAuthotrize
    if (token.expiresAt == null) {
      return false;
    }

    if (token.expiresAt < DateTime.now().millisecondsSinceEpoch / 1000) {
      return true;
    } else {
      return false;
    }
  }

  ///
  Future<Fault> uploadActivity(
      String name, String desc, String filepath) async {
    bool isAuthOk = false;
    var _strava = Strava(true, secret);

    isAuthOk = await isAuthorized();
    if (isAuthOk == false) {
      return Fault(
          error.statusAuthError, 'Authentication has not been succesful');
    }

    Fault fault = await _strava.uploadActivity(name, desc, filepath, 'gpx');

    return fault;
  }
}
