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
  LatLng? currentPosition;
  Set<Marker> markers = {};
  GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();

    // ✅ Use correct database region
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
      "https://mata-vision-aid-74a74-default-rtdb.asia-southeast1.firebasedatabase.app",
    );

    dbRef = db.ref("location");

    listenToLocation();
  }

  /// Listen to Firebase location changes in real-time
  void listenToLocation() {
    dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        double lat = double.parse(data["lat"].toString());
        double lon = double.parse(data["lon"].toString());

        setState(() {
          currentPosition = LatLng(lat, lon);
          markers = {
            Marker(
              markerId: const MarkerId("userLocation"),
              position: currentPosition!,
              infoWindow: const InfoWindow(title: "User Location"),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue, // ✅ Blue marker
              ),
            )
          };
        });

        // Move camera when new data arrives
        if (mapController != null && currentPosition != null) {
          mapController!.animateCamera(
            CameraUpdate.newLatLng(currentPosition!),
          );
        }

        debugPrint("Fetched location: lat=$lat, lon=$lon");
      } else {
        debugPrint("No location data in Firebase!");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live GPS Tracking"),
        backgroundColor: const Color(0xFF0073B1), // ✅ Matches theme
      ),
      body: currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: currentPosition!,
              zoom: 16,
            ),
            markers: markers,
            onMapCreated: (controller) {
              mapController = controller;
            },
            zoomControlsEnabled: false, // hide default +/- buttons
          ),

          // ✅ Floating recenter button
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
