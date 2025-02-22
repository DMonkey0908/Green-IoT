import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider with ChangeNotifier {
  bool _isNotificationEnabled = true;

  bool get isNotificationEnabled => _isNotificationEnabled;

  NotificationProvider() {
    _loadNotificationPreference();
  }

  // Load trạng thái thông báo từ SharedPreferences
  void _loadNotificationPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isNotificationEnabled = prefs.getBool('isNotificationEnabled') ?? true;
    notifyListeners();
  }

  // Thay đổi trạng thái thông báo và lưu vào SharedPreferences
  void toggleNotification() async {
    _isNotificationEnabled = !_isNotificationEnabled;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isNotificationEnabled', _isNotificationEnabled);
    notifyListeners();
  }
}
