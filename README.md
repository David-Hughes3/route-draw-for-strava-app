# route_draw_for_strava

CS4990 project in Mobile Application Development

Route Draw for Strava is an application that allows a Strava user to upload a hand-drawn route as a Strava activity.

## The Problem

The Strava mobile app allows a user to create an activity, but it down not allow a user to attach a
gpx file or draw their own route. I recently ran into this issue myself where my GPS watch was inaccurate,
so the image of the route was both misleading and frustrating to me.

## Secrets

in lib/secret.dart
```
final String secret = "[Strava API client secret]";
final String clientId = "[Strava API appID]";
final String GOOGLE_MAPS_API_KEY = "YOUR KEY HERE";
```

substitute Google api key in ios/Runner/AppDelegate.swift
```
<meta-data android:name="com.google.android.geo.API_KEY"
            android:value="YOUR KEY HERE"/>
```

substitute Google api key in android/app/src/main/AndroidManifest.xml
```
GMSServices.provideAPIKey("YOUR KEY HERE")
```

## Flutter Starting Demo App Info

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
