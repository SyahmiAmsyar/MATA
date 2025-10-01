import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref("location");

  Stream<Map<String, double>> getLocationStream() {
    return dbRef.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) {
        return {"lat": 0.0, "lon": 0.0};
      }

      double lat = 0.0;
      double lon = 0.0;

      // ✅ Case A: flat structure
      if (data.containsKey("lat") && data.containsKey("lon")) {
        lat = double.tryParse(data["lat"].toString()) ?? 0.0;
        lon = double.tryParse(data["lon"].toString()) ?? 0.0;
      }
      // ✅ Case B: nested structure
      else if (data.containsKey("raspberry")) {
        final nested = data["raspberry"] as Map?;
        if (nested != null) {
          lat = double.tryParse(nested["lat"].toString()) ?? 0.0;
          lon = double.tryParse(nested["lon"].toString()) ?? 0.0;
        }
      }

      return {"lat": lat, "lon": lon};
    });
  }
}
