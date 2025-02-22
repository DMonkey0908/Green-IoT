import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo2/authencation/Account.dart';
import 'package:demo2/authencation/Login.dart';
import 'package:demo2/components/QRScannerPage.dart';
import 'package:demo2/services/users_list.dart';
import 'package:demo2/themes/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:demo2/services/NotificationProvider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/versionchecker.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  bool isUserExists = false;

  void checkUserInFirestore() async {
    String user = FirebaseAuth.instance.currentUser!.email.toString();
    String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');

    // Reference to the Firestore collection
    CollectionReference adminUsers = FirebaseFirestore.instance.collection('ADMIN_USERS');

    // Check if the user exists in the "ADMIN_USERS" collection
    final snapshot = await adminUsers.doc(modifiedUser).get();

    // Check if the document exists and if the EMAIL field matches the current user's email
    if (snapshot.exists) {
      // Cast the data to Map<String, dynamic>
      Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

      // Check if the EMAIL field is not null and matches the current user's email
      String? emailField = data?['EMAIL'];
      setState(() {
        isUserExists = (emailField == user);
      });
    } else {
      setState(() {
        isUserExists = false; // User does not exist
      });
    }
  }


  @override
  void initState() {
    super.initState();
    checkUserInFirestore();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeProvider>(context); // Dùng ThemeProvider để lấy theme

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Row(
          children: [
            Icon(Icons.settings),
            SizedBox(width: 10,),
            Container(
              margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: Text(
                'Cài đặt',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Spacer(),
            IconButton(
              onPressed: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (context)=> QRScannerPage()));
              },
              icon: Icon(Icons.qr_code_scanner,size: 26,),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.white,
          ),
          Center(
            child: Opacity(
              opacity: 0.1, // Độ mờ của hình ảnh
              child: SizedBox(
                width: 400, // Chiều rộng giới hạn
                height: 400, // Chiều cao giới hạn
                child: Image.asset(
                  'assets/images/main_logo.png', // Đường dẫn tới hình ảnh
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          ListView(
            children: [
              SizedBox(height: 10),
              Consumer<NotificationProvider>(
                builder: (context,notificationProvider,child){
                  return ListTile(
                    title: Text('Thông báo',style: TextStyle(fontWeight: FontWeight.bold),),
                    trailing: Switch(
                      activeColor: Theme.of(context).colorScheme.onSurface,
                      value: notificationProvider.isNotificationEnabled,
                      onChanged: (bool value) {
                        notificationProvider.toggleNotification();
                      },
                    ),
                  );
                },
              ),
              ListTile(
                title: Text('Chế độ tối màu',style: TextStyle(fontWeight: FontWeight.bold),),
                subtitle: Text("Thay đổi giao diện"),
                trailing: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return Switch(
                      value: themeProvider.isDarkMode, // Sử dụng giá trị từ ThemeProvider
                      onChanged: (bool value) {
                        themeProvider.toggleTheme(); // Toggle và lưu trạng thái darkMode
                      },
                    );
                  },
                ),
              ),
              ListTile(
                title: Row(
                  children: [
                    Text('Cài đặt tài khoản',style: TextStyle(fontWeight: FontWeight.bold),),
                    SizedBox(width: 10),
                    Icon(Icons.account_circle),
                  ],
                ),
                subtitle: Text("Quản lý thông tin tài khoản của bạn"),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => Account()));
                },
              ),
              ListTile(
                title: Row(
                  children: [
                    Text('Cài đặt ngôn ngữ',style: TextStyle(fontWeight: FontWeight.bold),),
                    SizedBox(width: 10),
                    Icon(Icons.language),
                  ],
                ),
                subtitle: Text(_selectedLanguage),
                onTap: () {
                  _showLanguageDialog();
                },
              ),
              ListTile(
                title: Row(
                  children: [
                    Text('Kiểm tra cập nhật',style: TextStyle(fontWeight: FontWeight.bold),),
                    SizedBox(width: 10),
                    Icon(Icons.update),
                  ],
                ),
                subtitle: FutureBuilder<String>(
                  future: _getCurrentVersion(), // Lấy phiên bản hiện tại
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text("Đang kiểm tra...");
                    } else if (snapshot.hasError) {
                      return Text("Không thể lấy thông tin phiên bản.");
                    }
                    return Text("Phiên bản hiện tại: ${snapshot.data}");
                  },
                ),
                onTap: () async {
                  final versionChecker = VersionChecker();
                  await versionChecker.checkForUpdate(context); // Kiểm tra cập nhật
                },
              ),
              Visibility(
                visible: (isUserExists),
                child: ListTile(
                  title: Row(
                    children: [
                      Text('Chia sẽ dữ liệu người dùng',style: TextStyle(fontWeight: FontWeight.bold),),
                      Spacer(),
                      Icon(Icons.diamond, color: Colors.yellow[800]),
                    ],
                  ),
                  subtitle: Text("Cấp quyền truy cập thiết bị cho các thành viên",style: TextStyle(fontSize: 12),),
                  onTap: () {
                    Navigator.push(
                        context, MaterialPageRoute(builder: (context) => UsersList()));
                  },
                ),
              ),
              ListTile(
                title: Text('Đăng xuất',style: TextStyle(fontWeight: FontWeight.bold),),
                subtitle: Text("Đăng xuất tài khoản"),
                onTap: () {
                  _showDialog(context);
                },
                trailing: Icon(Icons.exit_to_app, color: Colors.grey),
              ),
            ],
          ),
        ]
      ),
    );
  }

  Future<String> _getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      print("Error fetching version: $e");
      return "Không xác định";
    }
  }

  // Hàm hiển thị hộp thoại chọn ngôn ngữ
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          title: Text('Chọn ngôn ngữ'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Text('Tiếng Việt'),
                  value: 'Tiếng Việt',
                  groupValue: _selectedLanguage,
                  activeColor: Theme.of(context).colorScheme.surfaceTint,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedLanguage = value!;
                    });
                    Navigator.of(context).pop();
                  },
                ),
                RadioListTile<String>(
                  title: Text('English'),
                  value: 'English',
                  groupValue: _selectedLanguage,
                  activeColor: Theme.of(context).colorScheme.surfaceTint,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedLanguage = value!;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Hàm hiển thị hộp thoại đăng xuất (nếu cần)
  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          title: Text('Đăng xuất',style: TextStyle(fontWeight: FontWeight.bold,),),
          content: Text('Bạn có chắc chắn muốn đăng xuất không?'),
          actions: <Widget>[
            TextButton(
              child: Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Theme.of(context).colorScheme.primaryContainer),
              ),
              child: Text('Đăng xuất',style: TextStyle(color: Colors.black),),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pop();
                Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
              },
            ),
          ],
        );
      },
    );
  }
}
