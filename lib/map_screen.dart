import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'address_info.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as map_tool;
import "package:geolocator/geolocator.dart";
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarker;

  LatLng userLocation = LatLng(15.392289, 75.024795); // default location

  bool isInSelectedArea = false;

  DateTime? entryTime;
  DateTime? exitTime;

  List<LatLng> polygonPoints = const [
    LatLng(15.3927825, 75.0251256),
    LatLng(15.3928206, 75.0252130),
    LatLng(15.3927570, 75.0252412),
    LatLng(15.3927237, 75.0251815),
    LatLng(15.3927825, 75.0251256),
  ];

  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    initNotifications();
    getCurrentLocation();
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'geofence_channel',
          'Geofence Notifications',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  void addCustomIcon() {
    BitmapDescriptor.asset(
      const ImageConfiguration(),
      "assets/Location_marker.png",
    ).then((icon) {
      setState(() {
        markerIcon = icon;
      });
    });
  }

  void getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return;
      }
    }

    // Get location updates
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((Position position) async {
      LatLng newLocation = LatLng(position.latitude, position.longitude);
      checkUpdatedLocation(newLocation);

      setState(() {
        userLocation = newLocation;
        updateMarker();
      });

      // Move camera to new location
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLng(userLocation));
    });
  }

  void updateMarker() {
    setState(() {
      markers.clear();
      markers.add(
        Marker(
          markerId: const MarkerId("live_location"),
          position: userLocation,
          icon: BitmapDescriptor.defaultMarker,
        ),
      );
    });
  }

  void checkUpdatedLocation(LatLng pointLatLng) async {
    List<map_tool.LatLng> convertedPolygonPoints =
        polygonPoints
            .map((point) => map_tool.LatLng(point.latitude, point.longitude))
            .toList();

    bool insideGeofence = map_tool.PolygonUtil.containsLocation(
      map_tool.LatLng(pointLatLng.latitude, pointLatLng.longitude),
      convertedPolygonPoints,
      false,
    );

    if (insideGeofence && !isInSelectedArea) {
      // User entered geofence
      showNotification("Geofence Alert", "You have entered the geofence!");
      entryTime = DateTime.now();
      isInSelectedArea = true;
      _storeTimestamp(entryTime!, "entry");
      // Call mark attendance when user enters the geofence
      await _markAttendanceIfInSession(entryTime!);
    } else if (!insideGeofence && isInSelectedArea) {
      // User exited geofence
      showNotification("Geofence Alert", "You have exited the geofence!");
      exitTime = DateTime.now();
      isInSelectedArea = false;
      _storeTimestamp(exitTime!, "exit");
      if (entryTime != null) {
        Duration duration = exitTime!.difference(entryTime!);
        _storeDuration(entryTime!, exitTime!, duration);
      }
    }

    setState(() {});
  }

  String getUserId() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      return user.email!.substring(0, 8); // Extract first 8 characters
    }
    return "unknown"; // Default if no user is logged in
  }

  void _storeTimestamp(DateTime timestamp, String type) {
    String userId = getUserId();
    FirebaseFirestore.instance.collection('geofence_logs').add({
      'user_id': userId,
      'timestamp': timestamp.toIso8601String(),
      'type': type, // "entry" or "exit"
    });
  }

  void _storeDuration(DateTime entry, DateTime exit, Duration duration) {
    String userId = getUserId();
    FirebaseFirestore.instance.collection('geofence_durations').add({
      'user_id': userId,
      'entry_time': entry.toIso8601String(),
      'exit_time': exit.toIso8601String(),
      'duration': duration.inSeconds, // Store in seconds
    });
  }

  Future<void> _markAttendanceIfInSession(DateTime entryTime) async {
    String userId = getUserId();

    QuerySnapshot sessionSnapshot =
        await FirebaseFirestore.instance
            .collection('sessions')
            .where('date', isEqualTo: entryTime.toIso8601String().split('T')[0])
            .get();

    for (var session in sessionSnapshot.docs) {
      String sessionId = session['session_id'];
      TimeOfDay startTime = TimeOfDay(
        hour: int.parse(session['start_time'].split(':')[0]),
        minute: int.parse(session['start_time'].split(':')[1]),
      );
      TimeOfDay endTime = TimeOfDay(
        hour: int.parse(session['end_time'].split(':')[0]),
        minute: int.parse(session['end_time'].split(':')[1]),
      );

      DateTime startDateTime = DateTime(
        entryTime.year,
        entryTime.month,
        entryTime.day,
        startTime.hour,
        startTime.minute,
      );
      DateTime endDateTime = DateTime(
        entryTime.year,
        entryTime.month,
        entryTime.day,
        endTime.hour,
        endTime.minute,
      );

      if (entryTime.isAfter(startDateTime) && entryTime.isBefore(endDateTime)) {
        // Mark attendance in Firestore
        await FirebaseFirestore.instance.collection('attendance').add({
          'session_id': sessionId,
          'user_id': userId,
          'status': 'present',
        });

        showNotification(
          "Attendance Marked",
          "You have been marked as present for session $sessionId",
        );
        break; // Exit after marking for one active session
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: userLocation,
                zoom: 18,
              ),
              onMapCreated: (controller) {
                _controller.complete(controller);
              },
              markers: markers,
              polygons: {
                Polygon(
                  polygonId: PolygonId("1"),
                  points: polygonPoints,
                  strokeWidth: 2,
                  strokeColor: Colors.red,
                  fillColor: const Color.fromARGB(150, 46, 159, 208),
                ),
              },
            ),
          ),
          AddressInfo(isIntheDeliveryArea: isInSelectedArea),
          const SizedBox(height: 10),
          // Displaying Entry and Exit Time
          if (entryTime != null)
            Text(
              "Entry Time: ${entryTime!.toLocal()}",
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          if (exitTime != null)
            Text(
              "Exit Time: ${exitTime!.toLocal()}",
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
