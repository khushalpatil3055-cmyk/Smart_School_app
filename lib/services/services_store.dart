import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';

class RedDotService {

  static Future<void> updateLastSeen(
      String folderKey,
      String userId) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(
      "${userId}_${folderKey}_last_seen",
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<bool> hasNewUpdate(
      String folderKey,
      String userId) async {

    final prefs = await SharedPreferences.getInstance();

    int lastSeen =
        prefs.getInt("${userId}_${folderKey}_last_seen") ?? 0;

    final snapshot = await FirebaseDatabase.instance
        .ref(folderKey)
        .child("lastUpdated")
        .get();

    if (snapshot.exists) {
      int lastUpdated = snapshot.value as int;
      return lastUpdated > lastSeen;
    }

    return false;
  }
}
