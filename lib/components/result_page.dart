import 'package:flutter/material.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:url_launcher/url_launcher.dart';

class ResultPage extends StatelessWidget {
  final String result;

  ResultPage({required this.result});

  @override
  Widget build(BuildContext context) {
    // Kiểm tra định dạng mã QR
    bool isWiFiQR = result.startsWith("WIFI:");
    bool isURL = result.startsWith("http://") || result.startsWith("https://");
    String? ssid;
    String? password;
    String? security;

    if (isWiFiQR) {
      final wifiData = result.substring(5); // Bỏ phần "WIFI:"
      final fields = wifiData.split(';');
      for (var field in fields) {
        if (field.startsWith("S:")) ssid = field.substring(2);
        if (field.startsWith("P:")) password = field.substring(2);
        if (field.startsWith("T:")) security = field.substring(2);
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimaryFixed,
      ),
      body: Container(
        color: Theme.of(context).colorScheme.onPrimaryFixed,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isWiFiQR && ssid != null && password != null)
                  Column(
                    children: [
                      Text(
                        'Thông tin WiFi phát hiện:',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      Text('SSID: $ssid'),
                      Text('Password: $password'),
                      Text('Security: $security'),
                      SizedBox(height: 32),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        onPressed: () => _connectToWiFi(context, ssid!, password!, security ?? 'WPA'),
                        child: Text(
                          'Kết nối WiFi',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  )
                else if (isURL)
                  Column(
                    children: [
                      Text(
                        'Đường link phát hiện:',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      Text(
                        result,
                        style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        onPressed: () => _openURL(result),
                        child: Text(
                          'Mở trong trình duyệt',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Text(
                        'Kết quả mã QR:',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      SelectableText(
                        result,
                        style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                        textAlign: TextAlign.center,
                        showCursor: true,
                        cursorColor: Colors.blue,
                        toolbarOptions: ToolbarOptions(
                          copy: true,
                          selectAll: true,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _connectToWiFi(BuildContext context, String ssid, String password, String security) async {
    try {
      bool isConnected = await WiFiForIoTPlugin.connect(
        ssid,
        password: password,
        security: security == 'WEP' ? NetworkSecurity.WEP : NetworkSecurity.WPA,
        joinOnce: true, // Chỉ kết nối một lần
      );

      if (isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kết nối thành công đến WiFi $ssid!',style: TextStyle(color: Theme.of(context).colorScheme.tertiaryFixed))),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kết nối thất bại. Vui lòng kiểm tra lại thông tin.',style: TextStyle(color: Theme.of(context).colorScheme.tertiaryFixed),)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi kết nối WiFi: $e',style: TextStyle(color: Theme.of(context).colorScheme.tertiaryFixed),)),
      );
    }
  }

  void _openURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Không thể mở URL: $url';
    }
  }
}
