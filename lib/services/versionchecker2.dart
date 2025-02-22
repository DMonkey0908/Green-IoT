import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class Versionchecker2 {
  Future<void> checkForUpdate(BuildContext context) async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setDefaults({'latest_version': '2.0.1'}); // Giá trị mặc định
      await remoteConfig.fetchAndActivate();

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final latestVersion = remoteConfig.getString('latest_version') ?? "0.0.0"; // Giá trị mặc định nếu null

      if (_isUpdateAvailable(currentVersion, latestVersion)) {
        _showUpdateDialog(context, latestVersion);
      }
    } catch (e) {
      print("Error checking for update: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Không thể kiểm tra phiên bản.")),
      );
    }
  }

  // Kiểm tra nếu cần cập nhật dựa trên phiên bản
  bool _isUpdateAvailable(String currentVersion, String latestVersion) {
    List<int> currentParts = currentVersion.split('.').map(int.parse).toList();
    List<int> latestParts = latestVersion.split('.').map(int.parse).toList();

    // Chỉ kiểm tra số thứ 2 (minor version) của phiên bản
    if (latestParts[1] > currentParts[1]) {
      return true;  // Cần cập nhật nếu số thứ 2 của phiên bản mới lớn hơn
    }

    return false; // Không cần cập nhật nếu số thứ 2 của phiên bản giống nhau hoặc nhỏ hơn
  }

  void _showUpdateDialog(BuildContext context, String latestVersion) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          title: Text("Cập nhật mới"),
          content: Text(
              "Phiên bản $latestVersion đã có sẵn. Vui lòng cập nhật ứng dụng để có trải nghiệm tốt hơn."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Bỏ qua"),
            ),
            TextButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                final updateUrl = 'https://drive.google.com/file/d/1FPbw0iDvL4XzGKWNAthuFJ0xK4gKw_TF/view?usp=drive_link';
                // Use launchUrl (newer method in url_launcher)
                if (await canLaunchUrl(Uri.parse(updateUrl))) {
                  await launchUrl(Uri.parse(updateUrl));
                } else {
                  // Show a snackbar if the URL cannot be launched
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Không thể mở liên kết!")),
                  );
                }
              },
              child: Text("Cập nhật"),
            ),
          ],
        );
      },
    );
  }
}
