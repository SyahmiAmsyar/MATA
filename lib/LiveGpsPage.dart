import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class LiveGpsPage extends StatefulWidget {
  const LiveGpsPage({super.key});

  @override
  State<LiveGpsPage> createState() => _LiveGpsPageState();
}

class _LiveGpsPageState extends State<LiveGpsPage> {
  late DatabaseReference dbRef;
  GoogleMapController? mapController;
  LatLng? currentPosition;
  LatLng? lastPosition;
  Marker? liveMarker;

  bool autoFollow = true; // ✅ Auto-follow camera toggle

  @override
  void initState() {
    super.initState();

    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
      "https://mata-vision-aid-74a74-default-rtdb.asia-southeast1.firebasedatabase.app",
    );

    dbRef = db.ref("location");
    listenToLocation();
  }

  /// ✅ Listen to real-time GPS location updates
  void listenToLocation() {
    dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) {
        debugPrint("⚠️ No location data in Firebase!");
        return;
      }

      double lat = double.parse(data["lat"].toString());
      double lon = double.parse(data["lon"].toString());
      final newPosition = LatLng(lat, lon);

      debugPrint("📍 Updated location: $lat, $lon");

      // Animate marker smoothly
      _animateMarkerTo(newPosition);
    });
  }

  /// ✅ Smoothly animate marker movement
  Future<void> _animateMarkerTo(LatLng newPosition) async {
    if (currentPosition == null) {
      // First time location
      setState(() {
        currentPosition = newPosition;
        liveMarker = Marker(
          markerId: const MarkerId("userLocation"),
          position: newPosition,
          infoWindow: const InfoWindow(title: "MATA Glasses Location"),
          icon:
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        );
      });
      return;
    }

    // Animate between old and new position
    const int steps = 20;
    const Duration stepDuration = Duration(milliseconds: 100);
    final latDiff = (newPosition.latitude - currentPosition!.latitude) / steps;
    final lonDiff = (newPosition.longitude - currentPosition!.longitude) / steps;

    for (int i = 0; i <= steps; i++) {
      await Future.delayed(stepDuration);
      final lat = currentPosition!.latitude + (latDiff * i);
      final lon = currentPosition!.longitude + (lonDiff * i);
      final interpolated = LatLng(lat, lon);

      setState(() {
        currentPosition = interpolated;
        liveMarker = Marker(
          markerId: const MarkerId("userLocation"),
          position: interpolated,
          infoWindow: const InfoWindow(title: "MATA Glasses Location"),
          icon:
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        );
      });

      if (autoFollow && mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLng(interpolated),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live GPS Tracking"),
        backgroundColor: const Color(0xFF0073B1),
        actions: [
          IconButton(
            icon: Icon(
              autoFollow ? Icons.gps_fixed : Icons.gps_not_fixed,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                autoFollow = !autoFollow;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(autoFollow
                      ? "Auto-follow enabled"
                      : "Auto-follow disabled"),
                ),
              );
            },
          ),
        ],
      ),
      body: currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: currentPosition!,
              zoom: 17,
            ),
            markers: liveMarker != null ? {liveMarker!} : {},
            onMapCreated: (controller) {
              mapController = controller;
            },
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF0073B1),
              child: const Icon(Icons.my_location, color: Colors.white),
              onPressed: () {
                if (mapController != null && currentPosition != null) {
                  mapController!.animateCamera(
                    CameraUpdate.newLatLng(currentPosition!),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
