import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:demo2/authencation/Login.dart';
import 'package:demo2/services/NotificationProvider.dart';
import 'package:demo2/themes/theme_provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'pages/homepage.dart';
import 'pages/devices.dart';
import 'package:demo2/pages/settings.dart';
import 'package:demo2/pages/helps.dart';

import 'services/Noti.dart';
import 'services/notification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseApp firebaseApp = await Firebase.initializeApp();
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      print('Message received: ${message.notification?.title}, ${message.notification?.body}');
      // Hiển thị thông báo tại đây nếu cần
    }
  });

  // Xử lý thông báo khi người dùng nhấn vào thông báo
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Message clicked: ${message.notification?.title}');
    // Điều hướng đến trang khác nếu cần
  });

  // Lấy FCM Token
  String? token = await messaging.getToken();
  print("Firebase Messaging Token: $token");

  // Khởi tạo FlutterBackgroundService
  FlutterBackgroundService.initialize(() {
    // Ensure the service is running
    FlutterBackgroundService().sendData({"status": "service started"});

    // Start checking device status
    _checkDeviceStatus();

    // Listen for data received in the background service
    FlutterBackgroundService().onDataReceived.listen((event) {
      print('Data received: $event');
    });
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MyApp(),
    ),
  );
}

// Hàm này sẽ chạy trong nền
void onBackgroundServiceStart() {
  // Đảm bảo dịch vụ nền đang hoạt động
  FlutterBackgroundService().sendData({"status": "service started"});

  // Bắt đầu kiểm tra trạng thái thiết bị
  _checkDeviceStatus();

  // Lắng nghe các sự kiện dữ liệu nhận được trong dịch vụ nền
  FlutterBackgroundService().onDataReceived.listen((event) {
    print('Data received: $event');
  });
}

// Hàm để lấy giá trị từ Firebase và cập nhật thông báo
Future<void> _checkDeviceStatus() async {
  final user = FirebaseAuth.instance.currentUser!;
  String modifiedUser = user.email!.replaceAll('.', '').replaceAll('@gmail.com', '');
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  Noti.initialize(flutterLocalNotificationsPlugin);

  DatabaseReference alertRef = FirebaseDatabase.instance
      .ref()
      .child("${modifiedUser}")
      .child("ALERT")
      .child("VALUE"); // Đường dẫn đến ALERT.VALUE

  // Lấy giá trị value3 từ Firebase
  alertRef.once().then((DatabaseEvent event) {
    DataSnapshot snapshot = event.snapshot; // Chuyển từ DatabaseEvent sang DataSnapshot
    if (snapshot.exists) {
      String value3 = snapshot.value.toString();

      // Kiểm tra giá trị value3 và gửi thông báo nếu có sự cố
      if (value3 == "1") {
        Noti.showBigTextNotification(
          title: "Cảnh báo khẩn!!!",
          body: "Có sự cố xảy ra trên thiết bị của bạn!",
          fln: flutterLocalNotificationsPlugin,
          id: 0,
        );
        String formatTime(DateTime time) {
          return DateFormat('y MMM EEEE d hh:mm a').format(time);
        }
        Notifications notisave = Notifications(
          null,
          "Cảnh báo khẩn!!!",
          "Có sự cố xảy ra trên thiết bị của bạn!",
          "${formatTime(DateTime.now())}",
        );
      }
    }
  }).catchError((error) {
    print("Lỗi khi lấy giá trị từ Firebase: $error");
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>( // Sử dụng Consumer cho ThemeProvider
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Flutter Demo',
          theme: themeProvider.themeData, // Sử dụng themeProvider thay vì themeNotifier
          home: SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Check the current user status
    Future.delayed(Duration(seconds: 3), () async {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // No user is signed in, navigate to login page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        // User is signed in, navigate to home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage(title: '')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 40,),
            SizedBox(height: 60,width: 340,child: Image.asset("assets/images/iuh.png",height: 50,width: 240,)),
            SizedBox(height: 70,),
            SizedBox(
              width: 500,
              height: 500,
              child: Image.asset("assets/images/main_logo.png"),
            ),
            Spacer(),
            BottomAppBar(
              color: Colors.white,
              child: Text(
                "Powered by Nguyễn Hoàng Duy in company with Nguyễn Thế Kỳ Sương",
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'serif',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedIndex = 0;
  Widget MyHome = Home();
  Widget MyDevices = DeviceScreen();
  Widget MyHelps = Helps();
  Widget MySetting = SettingsPage();

  final List<String> titles = ["Nhà", "Thiết bị", "Trợ giúp", "Cài đặt"];
  final List<IconData> icons = [
    Ionicons.home,
    Ionicons.hardware_chip,
    Ionicons.help_circle,
    Ionicons.settings
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: getBody(),
      bottomNavigationBar: BottomNavigationBar(
        iconSize: 35,
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        selectedItemColor: Theme.of(context).colorScheme.inversePrimary,
        unselectedItemColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.onSurface
            : Colors.grey,
        items: List.generate(icons.length, (index) {
          return BottomNavigationBarItem(
            icon: Icon(
              icons[index],
              size: 25,
              color: selectedIndex == index
                  ? Theme.of(context).colorScheme.inversePrimary
                  : Colors.grey,
            ),
            label: titles[index],
          );
        }),
        onTap: (int index) {
          onTapHandler(index);
        },
      ),
    );
  }

  Widget getBody() {
    if (selectedIndex == 0) {
      return MyHome;
    } else if (selectedIndex == 1) {
      return MyDevices;
    } else if (selectedIndex == 2) {
      return MyHelps;
    } else {
      return MySetting;
    }
  }

  void onTapHandler(int index) {
    setState(() {
      selectedIndex = index;
    });
  }
}
