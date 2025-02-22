import 'package:demo2/themes/light_mode.dart';
import 'package:demo2/themes/dark_mode.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData = lightMode;

  ThemeProvider() {
    _loadTheme(); // Tải trạng thái Dark Mode khi khởi tạo
  }

  ThemeData get themeData => _themeData;

  bool get isDarkMode => _themeData == darkMode;

  set themeData(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeData == lightMode) {
      themeData = darkMode;
      _saveTheme(true); // Lưu trạng thái Dark Mode
    } else {
      themeData = lightMode;
      _saveTheme(false); // Lưu trạng thái Light Mode
    }
  }

  // Lưu trạng thái Dark Mode vào SharedPreferences
  Future<void> _saveTheme(bool isDarkMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  // Tải trạng thái Dark Mode từ SharedPreferences
  Future<void> _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isDarkMode = prefs.getBool('isDarkMode') ?? false; // Mặc định là Light Mode nếu chưa lưu
    themeData = isDarkMode ? darkMode : lightMode;
  }
}
