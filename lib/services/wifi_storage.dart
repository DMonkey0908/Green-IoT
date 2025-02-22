import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class WiFiStorage {
  static const String _wifiListKey = 'savedWiFiList';

  // Save a list of WiFi credentials
  static Future<void> saveWiFiList(List<Map<String, String>> wifiList) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String wifiListJson = jsonEncode(wifiList);
    await prefs.setString(_wifiListKey, wifiListJson);
  }

  // Get the list of saved WiFi credentials
  static Future<List<Map<String, String>>> getWiFiList() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? wifiListJson = prefs.getString(_wifiListKey);

    if (wifiListJson != null) {
      List<dynamic> jsonList = jsonDecode(wifiListJson);
      return jsonList.map((wifi) => Map<String, String>.from(wifi)).toList();
    }
    return [];
  }

  // Add a new WiFi entry
  static Future<void> addWiFi(String ssid, String password) async {
    List<Map<String, String>> wifiList = await getWiFiList();
    wifiList.add({'SSID': ssid, 'Password': password});
    await saveWiFiList(wifiList);
  }

  // Clear all saved WiFi credentials
  static Future<void> clearWiFiList() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_wifiListKey);
  }
}
