import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo2/services/Scanning.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import '../authencation/Account.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/Noti.dart';
import '../services/NotificationProvider.dart';
import '../services/database.dart';
import '../services/firebase_image_storage.dart';
import '../services/notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class DeviceScreen extends StatefulWidget {
  @override
  State<DeviceScreen> createState() => DevicesState();
}

class DevicesState extends State<DeviceScreen> {
  late DatabaseReference df;
  List<Device> _listdv = List.empty(growable: true);
  bool hasEsp32Sink = false;
  List<Device> _filteredDevices = []; // List of filtered devices
  TextEditingController _searchController = TextEditingController();

  List<String> users4 = [];

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin(); //variable notification library
  late Future<List<Notifications>> notisql; //future list notification get from sql
  List<Notifications> notifications = []; //list notification get from sql

  int id = 0;
  String? device_name = "";
  String? device_description = "";
  String? device_mode = '';
  String user="";
  String _searchText="";
  String userAvatarUrl='';
  String _sortOrder = "A-Z"; // Giá trị mặc định
  var dbHelper;

  final databaseReference = FirebaseDatabase.instance.ref().child("${FirebaseAuth.instance.currentUser!.email.toString().replaceAll('.', '').replaceAll('@gmail.com', '')}").child("USERS");

  String formatTime(DateTime time) {
    return DateFormat('y MMM EEEE d hh:mm a').format(time);
  }
  String formatTime2(DateTime time){
    return DateFormat('yMMEE').format(time);
  }

  void initState() {
    super.initState();
    _loadAvatar();
    dbHelper = DBHelper();
    readUserData();
    Noti.initialize(flutterLocalNotificationsPlugin);
    user = FirebaseAuth.instance.currentUser!.email.toString();
    String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');
    df = FirebaseDatabase.instance.ref();
    df.child("${modifiedUser}").child("DEVICES").onValue.listen((event) {
      List<Device> temp = List.empty(growable: true);
      print("read: ${event.snapshot.value.toString()}");
      for (final child in event.snapshot.children) {
        var encodedString = jsonEncode(child.value);
        Map<String, dynamic> valueMap = json.decode(encodedString);
        Device user = Device.fromJson(valueMap);
        if (user.name=='ESP32_SINK'){
          hasEsp32Sink = true;
        }
        setState(() {
          temp.add(user);
          _listdv.add(user);
        });
      }
      setState(() {
        _listdv = temp;
      });
    });
  }
  String _encodeDeviceId(String id) {
    if (id.length <= 6) {
      return "Invalid ID"; // Nếu id quá ngắn để mã hóa
    }

    // Bỏ 3 ký tự đầu và 3 ký tự cuối
    String trimmedId = id.substring(3, id.length - 3);

    // Nếu chuỗi sau khi cắt còn dưới 5 ký tự thì không thể thêm "20"
    if (trimmedId.length <= 4) {
      return "Invalid Encoded ID";
    }

    // Thêm chuỗi '20' sau ký tự thứ 4
    String encodedId = trimmedId.substring(0, 4) + "20" + trimmedId.substring(4);

    String formattedDate = encodedId.substring(0, 2) + '/' +
        encodedId.substring(2, 4) + '/' +
        encodedId.substring(4);

    return formattedDate;
  }

  void readUserData() async {
    databaseReference.once().then((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> values = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          users4 = values.keys.map((key) => key.toString()).toList();
        });
      }
    });
  }

  void _showDeviceInfoDialog(BuildContext context, Device device) {
    // String date_id = _encodeDeviceId(device.id);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          title: Text('Thông tin Node'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Mã thiết bị: ${device.name}"),
              SizedBox(height: 10,),
              Text("Địa chỉ IP: ${device.ip_add}"),
              // SizedBox(height: 10,),
              // Text("Ngày đăng kí: $date_id"),
              // Add more fields if needed
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.onPrimary
              ),
              child: Text('OK',style: TextStyle(color: Colors.white),),
            ),
          ],
        );
      },
    );
  }

  void _showDialog(BuildContext context, Device device) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          title: Text('Xóa thiết bị'),
          content: Text('Bạn có muốn xóa ${device.name}?'),
          actions: <Widget>[
            TextButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                foregroundColor: Colors.white,
              ),
              child: Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop(); // Đóng Dialog
              },
            ),
            TextButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                foregroundColor: Colors.white,
              ),
              child: Text('Có'),
              onPressed: () {
                final notificationProvider = Provider.of<NotificationProvider>(context,listen: false);
                deleteDevice(device.name);
                if (notificationProvider.isNotificationEnabled){
                  Noti.showBigTextNotification(
                      title: "Xóa thiết bị!",
                      body: "Bạn vừa mới xóa ${device.name}",
                      fln: flutterLocalNotificationsPlugin,
                      id: 0
                  );
                }
                user = FirebaseAuth.instance.currentUser!.email.toString();
                String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');
                Notifications notisave = Notifications(
                    null, "Xóa thiết bị", "Bạn vừa mới xóa: ${device.name}", "${formatTime(DateTime.now())}");
                dbHelper.save(notisave);
                df.child(modifiedUser).child("DEVICES").child("${device.name}").remove();
                df.child("DEVICES").child("${device.name}").remove();
                setState(() {
                  _listdv.remove(device);
                });
                Navigator.of(context).pop();
                // Đóng Dialog
              },
            ),
          ],
        );
      },
    );
  }

  void deleteDevice(String deviceId) {
    user = FirebaseAuth.instance.currentUser!.email.toString();
    String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');
    df.child("DEVICES").child(deviceId).child("VALUE").set("RESET"); // Gui lenh reset den esp truoc
    df.child("${modifiedUser}").child("DEVICES").child(deviceId).remove(); //xoa du lieu
  }

  void _showEditDialog(Device device, Type type) {
    TextEditingController nameController = TextEditingController(text: type.name_u);

    user = FirebaseAuth.instance.currentUser!.email.toString();
    String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          title: Text('Chỉnh sửa tên thiết bị'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                cursorColor: Colors.green,
                decoration: InputDecoration(
                    labelText: 'Tên thiết bị',
                    labelStyle: TextStyle(
                        color: Colors.black
                    ),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.green
                        )
                    )
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Hủy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.withOpacity(0.4),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.6),
                foregroundColor: Colors.white,
              ),
              child: Text('Lưu'),
              onPressed: () {
                setState(() {
                  type.name_u = nameController.text;
                });

                df.child("${modifiedUser}").child("DEVICES").child("${device.name}").child("TYPE").child("${type.name}").update({
                  'NAME_U': type.name_u,
                });

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  void _showEditDialog2(Device device, Type type) {
    TextEditingController nameController = TextEditingController(text: type.name_u2);

    user = FirebaseAuth.instance.currentUser!.email.toString();
    String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Chỉnh sửa tên thiết bị'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                cursorColor: Colors.green,
                decoration: InputDecoration(
                    labelText: 'Tên thiết bị',
                    labelStyle: TextStyle(
                        color: Colors.green
                    ),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.green
                        )
                    )
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Hủy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF93c47d),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF93c47d),
                foregroundColor: Colors.white,
              ),
              child: Text('Lưu'),
              onPressed: () {
                setState(() {
                  type.name_u2 = nameController.text;
                });

                df.child("${modifiedUser}").child("DEVICES").child("ESP8266_CT_3${device.ma}").child("TYPE").child("CT_3").update({
                  'NAME_U2': type.name_u2,
                });

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  void _showEditDialog3(Device device, Type type) {
    TextEditingController nameController = TextEditingController(text: type.name_u3);

    user = FirebaseAuth.instance.currentUser!.email.toString();
    String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Chỉnh sửa tên thiết bị'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                cursorColor: Colors.green,
                decoration: InputDecoration(
                    labelText: 'Tên thiết bị',
                    labelStyle: TextStyle(
                        color: Colors.green
                    ),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.green
                        )
                    )
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Hủy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF93c47d),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF93c47d),
                foregroundColor: Colors.white,
              ),
              child: Text('Lưu'),
              onPressed: () {
                setState(() {
                  type.name_u3 = nameController.text;
                });

                df.child("${modifiedUser}").child("DEVICES").child("ESP8266_CT_3${device.ma}").child("TYPE").child("CT_3").update({
                  'NAME_U3': type.name_u3,
                });

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void sendDataToAllUsers(String deviceName, String typeName, String modeString1) async {
    // Lấy email của user hiện tại và chỉnh sửa lại để phù hợp với Firebase
    String user = FirebaseAuth.instance.currentUser!.email.toString();
    String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');

    // dbRef1: Để đọc danh sách các user có trong "USERS"
    DatabaseReference dbRef1 = FirebaseDatabase.instance.ref().child("${modifiedUser}").child("USERS");

    // dbRef2: Để gửi dữ liệu tới các user
    DatabaseReference dbRef2 = FirebaseDatabase.instance.ref();

    // Lấy tất cả các user từ dbRef1
    DataSnapshot snapshot = await dbRef1.once().then((DatabaseEvent event) => event.snapshot);

    if (snapshot.value != null) {
      Map<dynamic, dynamic> usersMap = snapshot.value as Map<dynamic, dynamic>;

      // Duyệt qua tất cả các user và gửi dữ liệu tới từng user
      usersMap.forEach((userKey, userData) {
        // Sử dụng dbRef2 để gửi dữ liệu tới từng user
        dbRef2.child("$userKey").child("DEVICES").child(deviceName)
            .child("TYPE").child(typeName).child("VALUE").set(modeString1);

        dbRef2.child("$userKey").child("DEVICES").child(deviceName)
            .child("TYPE").child(typeName).child("VALUE2").set(modeString1);

        dbRef2.child("$userKey").child("DEVICES").child(deviceName)
            .child("TYPE").child(typeName).child("VALUE3").set(modeString1);

        dbRef2.child("$userKey").child("DEVICES").child(deviceName)
            .child("TYPE").child(typeName).child("VALUE4").set(modeString1);

        print("Data sent to user: $userKey");
      });
    } else {
      print("No users found in the database.");
    }
  }

  final FirebaseImageStorage _firebaseImageStorage = FirebaseImageStorage();
  File? _localAvatarFile;

  /// Tải và hiển thị ảnh từ bộ nhớ cục bộ hoặc từ Firebase Storage
  Future<void> _loadAvatar() async {
    final file = await _firebaseImageStorage.getOrDownloadAvatar();
    setState(() {
      _localAvatarFile = file;
    });
  }

  final TextEditingController _textController = TextEditingController();

  Future<void> _showTimePickerDialogOn2(Device device, Type type) async {
    user = FirebaseAuth.instance.currentUser!.email.toString();
    String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');

    // Hiển thị hộp thoại chọn thời gian
    TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        cancelText: "Hủy",
        helpText: "Chọn thời gian bật",
        confirmText: "Đặt",
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              timePickerTheme: TimePickerThemeData(
                backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                hourMinuteColor: Theme.of(context).colorScheme.tertiaryContainer,
                hourMinuteTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 50,
                    fontWeight: FontWeight.bold
                ),
                dialBackgroundColor: Theme.of(context).colorScheme.secondary,
                dialHandColor: Colors.grey[800],
              ),
            ),
            child: child!,
          );
        }
    );

    if (pickedTime != null) {
      // Tính toán giá trị thời gian được chọn
      DateTime now = DateTime.now();
      DateTime selectedTime = DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      // Tính khoảng thời gian trừ đi thời gian hiện tại
      Duration difference = selectedTime.difference(now);
      int millisecondsDifference = difference.inMilliseconds;

      if (millisecondsDifference > 0) {
        print("Thời gian đã chọn trừ thời gian hiện tại (ms): $millisecondsDifference");

        // Cập nhật Firebase chỉ với giá trị thời gian
        df.child("DEVICES").child("${device.name}").child("VALUE").set("n1");
        df.child("$modifiedUser").child("DEVICES").child("${device.name}").child("TYPE").child(type.name).child("VALUE2").set("n1");

        await Future.delayed(Duration(seconds: 5));

        df.child("DEVICES").child("${device.name}").child("VALUE").set("/timer/1n/${millisecondsDifference.toString()}");

      } else {
        SnackBar(content: Text("Thời gian đã chọn nhỏ hơn thời gian hiện tại.",style: TextStyle(color: Theme.of(context).colorScheme.tertiaryFixed),),backgroundColor: Theme.of(context).colorScheme.tertiary,);
      }
    }
  }
  Future<void> _showTimePickerDialogOff2(Device device, Type type) async {
    user = FirebaseAuth.instance.currentUser!.email.toString();
    String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');

    // Hiển thị hộp thoại chọn thời gian
    TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        cancelText: "Hủy",
        helpText: "Chọn thời gian tắt",
        confirmText: "Đặt",
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              timePickerTheme: TimePickerThemeData(
                backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                hourMinuteColor: Theme.of(context).colorScheme.tertiaryContainer,
                hourMinuteTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 50,
                    fontWeight: FontWeight.bold
                ),
                dialBackgroundColor: Theme.of(context).colorScheme.onPrimary,
                dialHandColor: Colors.grey[800],
              ),
            ),
            child: child!,
          );
        }
    );

    if (pickedTime != null) {
      // Tính toán giá trị thời gian được chọn
      DateTime now = DateTime.now();
      DateTime selectedTime = DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      // Tính khoảng thời gian trừ đi thời gian hiện tại
      Duration difference = selectedTime.difference(now);
      int millisecondsDifference = difference.inMilliseconds;

      if (millisecondsDifference > 0) {
        print("Thời gian đã chọn trừ thời gian hiện tại (ms): $millisecondsDifference");

        // Cập nhật Firebase chỉ với giá trị thời gian
        df.child("DEVICES").child("${device.name}").child("VALUE").set("f1");
        df.child("$modifiedUser").child("DEVICES").child("${device.name}").child("TYPE").child(type.name).child("VALUE2").set("f1");

        await Future.delayed(Duration(seconds: 5));

        df.child("DEVICES").child("${device.name}").child("VALUE").set("/timer/1f/${millisecondsDifference.toString()}");
      } else {
        SnackBar(content: Text("Thời gian đã chọn nhỏ hơn thời gian hiện tại.",style: TextStyle(color: Theme.of(context).colorScheme.tertiaryFixed),),backgroundColor: Theme.of(context).colorScheme.tertiary,);
      }
    }
  }
  Future<void> _showTimePickerDialogOn3(Device device, Type type) async {
    user = FirebaseAuth.instance.currentUser!.email.toString();
    String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');

    // Hiển thị hộp thoại chọn thời gian
    TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        cancelText: "Hủy",
        helpText: "Chọn thời gian bật",
        confirmText: "Đặt",
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              timePickerTheme: TimePickerThemeData(
                backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                hourMinuteColor: Theme.of(context).colorScheme.tertiaryContainer,
                hourMinuteTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 50,
                    fontWeight: FontWeight.bold
                ),
                dialBackgroundColor: Theme.of(context).colorScheme.onPrimary,
                dialHandColor: Colors.grey[800],
              ),
            ),
            child: child!,
          );
        }
    );

    if (pickedTime != null) {
      // Tính toán giá trị thời gian được chọn
      DateTime now = DateTime.now();
      DateTime selectedTime = DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      // Tính khoảng thời gian trừ đi thời gian hiện tại
      Duration difference = selectedTime.difference(now);
      int millisecondsDifference = difference.inMilliseconds;

      if (millisecondsDifference > 0) {
        print("Thời gian đã chọn trừ thời gian hiện tại (ms): $millisecondsDifference");

        // Cập nhật Firebase chỉ với giá trị thời gian
        df.child("DEVICES").child("${device.name}").child("VALUE").set("n2");
        df.child("$modifiedUser").child("DEVICES").child("${device.name}").child("TYPE").child(type.name).child("VALUE3").set("n2");

        await Future.delayed(Duration(seconds: 5));

        df.child("DEVICES").child("${device.name}").child("VALUE").set("/timer/2n/${millisecondsDifference.toString()}");
      } else {
        SnackBar(content: Text("Thời gian đã chọn nhỏ hơn thời gian hiện tại.",style: TextStyle(color: Theme.of(context).colorScheme.tertiaryFixed),),backgroundColor: Theme.of(context).colorScheme.tertiary,);
      }
    }
  }
  Future<void> _showTimePickerDialogOff3(Device device, Type type) async {
    user = FirebaseAuth.instance.currentUser!.email.toString();
    String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');

    // Hiển thị hộp thoại chọn thời gian
    TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        cancelText: "Hủy",
        helpText: "Chọn thời gian tắt",
        confirmText: "Đặt",
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              timePickerTheme: TimePickerThemeData(
                backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                hourMinuteColor: Theme.of(context).colorScheme.tertiaryContainer,
                hourMinuteTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 50,
                    fontWeight: FontWeight.bold
                ),
                dialBackgroundColor: Theme.of(context).colorScheme.onPrimary,
                dialHandColor: Colors.grey[800],
              ),
            ),
            child: child!,
          );
        }
    );

    if (pickedTime != null) {
      // Tính toán giá trị thời gian được chọn
      DateTime now = DateTime.now();
      DateTime selectedTime = DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      // Tính khoảng thời gian trừ đi thời gian hiện tại
      Duration difference = selectedTime.difference(now);
      int millisecondsDifference = difference.inMilliseconds;

      if (millisecondsDifference > 0) {
        print("Thời gian đã chọn trừ thời gian hiện tại (ms): $millisecondsDifference");

        // Cập nhật Firebase chỉ với giá trị thời gian
        df.child("DEVICES").child("${device.name}").child("VALUE").set("f2");
        df.child("$modifiedUser").child("DEVICES").child("${device.name}").child("TYPE").child(type.name).child("VALUE3").set("f2");

        await Future.delayed(Duration(seconds: 5));

        df.child("DEVICES").child("${device.name}").child("VALUE").set("/timer/2f/${millisecondsDifference.toString()}");
      } else {
        SnackBar(content: Text("Thời gian đã chọn nhỏ hơn thời gian hiện tại.",style: TextStyle(color: Theme.of(context).colorScheme.tertiaryFixed),),backgroundColor: Theme.of(context).colorScheme.tertiary,);
      }
    }
  }

  Future<void> _showTimePickerDialogOn4(Device device, Type type) async {
    user = FirebaseAuth.instance.currentUser!.email.toString();
    String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');

    // Hiển thị hộp thoại chọn thời gian
    TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        cancelText: "Hủy",
        helpText: "Chọn thời gian bật",
        confirmText: "Đặt",
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              timePickerTheme: TimePickerThemeData(
                backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                hourMinuteColor: Theme.of(context).colorScheme.tertiaryContainer,
                hourMinuteTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 50,
                    fontWeight: FontWeight.bold
                ),
                dialBackgroundColor: Theme.of(context).colorScheme.onPrimary,
                dialHandColor: Colors.grey[800],
              ),
            ),
            child: child!,
          );
        }
    );

    if (pickedTime != null) {
      // Tính toán giá trị thời gian được chọn
      DateTime now = DateTime.now();
      DateTime selectedTime = DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      // Tính khoảng thời gian trừ đi thời gian hiện tại
      Duration difference = selectedTime.difference(now);
      int millisecondsDifference = difference.inMilliseconds;

      if (millisecondsDifference > 0) {
        print("Thời gian đã chọn trừ thời gian hiện tại (ms): $millisecondsDifference");

        // Cập nhật Firebase chỉ với giá trị thời gian
        df.child("DEVICES").child("${device.name}").child("VALUE").set("n3");
        df.child("$modifiedUser").child("DEVICES").child("${device.name}").child("TYPE").child(type.name).child("VALUE4").set("n3");

        await Future.delayed(Duration(seconds: 5));

        df.child("DEVICES").child("${device.name}").child("VALUE").set("/timer/3n/${millisecondsDifference.toString()}");
      } else {
        SnackBar(content: Text("Thời gian đã chọn nhỏ hơn thời gian hiện tại.",style: TextStyle(color: Theme.of(context).colorScheme.tertiaryFixed),),backgroundColor: Theme.of(context).colorScheme.tertiary,);
      }
    }
  }
  Future<void> _showTimePickerDialogOff4(Device device, Type type) async {
    user = FirebaseAuth.instance.currentUser!.email.toString();
    String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');

    // Hiển thị hộp thoại chọn thời gian
    TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        cancelText: "Hủy",
        helpText: "Chọn thời gian tắt",
        confirmText: "Đặt",
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              timePickerTheme: TimePickerThemeData(
                backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                hourMinuteColor: Theme.of(context).colorScheme.tertiaryContainer,
                hourMinuteTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 50,
                    fontWeight: FontWeight.bold
                ),
                dialBackgroundColor: Theme.of(context).colorScheme.onPrimary,
                dialHandColor: Colors.grey[800],
              ),
            ),
            child: child!,
          );
        }
    );

    if (pickedTime != null) {
      // Tính toán giá trị thời gian được chọn
      DateTime now = DateTime.now();
      DateTime selectedTime = DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      // Tính khoảng thời gian trừ đi thời gian hiện tại
      Duration difference = selectedTime.difference(now);
      int millisecondsDifference = difference.inMilliseconds;

      if (millisecondsDifference > 0) {
        print("Thời gian đã chọn trừ thời gian hiện tại (ms): $millisecondsDifference");

        // Cập nhật Firebase chỉ với giá trị thời gian
        df.child("DEVICES").child("${device.name}").child("VALUE").set("f3");
        df.child("$modifiedUser").child("DEVICES").child("${device.name}").child("TYPE").child(type.name).child("VALUE4").set("f3");

        await Future.delayed(Duration(seconds: 5));

        df.child("DEVICES").child("${device.name}").child("VALUE").set("/timer/3f/${millisecondsDifference.toString()}");
      } else {
        SnackBar(content: Text("Thời gian đã chọn nhỏ hơn thời gian hiện tại.",style: TextStyle(color: Theme.of(context).colorScheme.tertiaryFixed),),backgroundColor: Theme.of(context).colorScheme.tertiary,);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    user = FirebaseAuth.instance.currentUser!.email.toString();
    String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');
    FirebaseFirestore.instance.collection('USERS').doc(modifiedUser).update({
      'DEVICES': "${_listdv.length}",
    });
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        // backgroundColor: Colors.white,
        body: Column(
          children: [
            Flexible(
              flex: 2,
              child: SizedBox(
                height: 900,
                width: 500,
                child: Stack(
                  children: [
                    Positioned(
                      top: 120,
                      left: (MediaQuery.of(context).size.width - 500) / 2,
                      bottom: 0.5,
                      child: SizedBox(
                        height: 900,
                        width: 500,
                        child: _buildListNODE(_listdv),
                      ),
                    ),
                    Container(
                      height: 100,
                      width: 400,
                      color: Theme.of(context).colorScheme.onPrimary,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 30,),
                        child: Row(
                          children: [
                            SizedBox(width: 23,),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => Account()));
                              },
                              child: _localAvatarFile == null
                                ? CircleAvatar(
                                radius: 17,
                                backgroundColor: Colors.grey[200],
                                child: CircularProgressIndicator(),
                              )
                                  : CircleAvatar(
                                radius: 15,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 17,
                                  backgroundImage: FileImage(_localAvatarFile!),
                                ),
                              ),
                            ),
                            SizedBox(width: 20,),
                            Container(
                              width: 220,
                              height: 35,
                              child: TextField(
                                controller: _textController,
                                onChanged: (value) => setState(() => _searchText = value),
                                decoration: InputDecoration(
                                  hintText: 'Tìm kiếm Node IoT',
                                  hintStyle: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.tertiaryContainer,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    size: 15,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  suffixIcon: _searchText.isNotEmpty
                                      ? IconButton(
                                    icon: Icon(Icons.clear, size: 15, color: Theme.of(context).colorScheme.onSurface),
                                    onPressed: () {
                                      setState(() {
                                          _searchText = "";
                                          _textController.clear();
                                      }
                                      );
                                    },
                                  )
                                      : null,
                                ),
                              ),
                            ),
                            SizedBox(width: 3,),
                            PopupMenuButton<String>(
                              color: Theme.of(context).colorScheme.tertiaryContainer,
                              icon: Icon(Icons.filter_alt_rounded, color: Colors.white, size: 25),
                              onSelected: (String value) {
                                setState(() {
                                  _sortOrder = value;
                                });
                              },
                              itemBuilder: (BuildContext context) => [
                                PopupMenuItem<String>(
                                  value: "A-Z",
                                  child: Text("Sắp xếp A → Z"),
                                ),
                                PopupMenuItem<String>(
                                  value: "Z-A",
                                  child: Text("Sắp xếp Z → A"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 98),
                      height: 50,
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: Row(
                        children: [
                          SizedBox(width: 20.0),
                          Text(
                            "Số NODE hiện có: ${_listdv.length}",
                            style: TextStyle(
                              fontSize: 16.0,
                            ),
                          ),
                          SizedBox(width: 45),
                          Container(
                            height: 35,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5)
                                  ),
                                  backgroundColor: Theme.of(context).colorScheme.onPrimary
                              ),
                              icon: Icon(Ionicons.add_circle, size: 16.0,color: Colors.black,), // Add icon
                              label: Text('Thêm NODE',style: TextStyle(color: Colors.black,fontSize: 12),),
                              onPressed: () {
                                // Your "thêm phòng" functionality here
                                Navigator.push(context, MaterialPageRoute(builder: (context) => Scanning(),));
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListNODE(List<Device> devices) {
    // Lọc danh sách thiết bị dựa trên _searchText
    List<Device> filteredDevices = devices.where((device) {
      // Kiểm tra nếu _searchText rỗng hoặc device.name chứa _searchText
      return _searchText.isEmpty || device.name.toLowerCase().contains(_searchText.toLowerCase());
    }).toList();

    // Sắp xếp danh sách theo _sortOrder
    if (_sortOrder == "A-Z") {
      filteredDevices.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortOrder == "Z-A") {
      filteredDevices.sort((a, b) => b.name.compareTo(a.name));
    }

    return ListView.builder(
      itemCount: filteredDevices.length,
      itemBuilder: (context, index) {
        return _buildListNode(filteredDevices[index]);
      },
    );
  }

  Widget _buildListNode(Device device) {
    if (device.name.contains('ESP32_SINK')) {
      return _buildNodeContainer2(device);
    }
    else if (device.name.contains('ESP8266_WEATHER') ){
      return _buildNodeContainer3(device);
    }
    else if (device.name.contains('ESP32_RGB') ){
      return _buildNodeContainer4(device);
    }
    else if (device.name.contains('ESP8266_CT_3') ){
      return _buildNODEContainer5(device);
    }
    else {
      return _buildNODEContainer(device);
    }
  }


  //--------------------------//
  // Build List NODE
  //-------------------------//
  Widget _buildNODEContainer5(Device device) {
    // Your implementation of _buildNODEContainer here
    user = FirebaseAuth.instance.currentUser!.email.toString();
    String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');

    // ... (rest of the code)

    return Container(
      width: 320,
      height: 200,
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 70),
      child: Column( // Use Column instead of Row
        children: [
          Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                SizedBox(width: 30,),
                Text("${device.name}", style: TextStyle(color: Colors.black,fontSize: 16,fontWeight: FontWeight.bold),),
                Spacer(),
                IconButton(
                  onPressed: () {
                    _showDeviceInfoDialog(context, device); // Show dialog on button press
                  },
                  icon: Icon(Icons.more_vert, color: Colors.black54),
                ),
                IconButton(
                    onPressed: (){
                      _showDialog(context, device);
                    },
                    icon: Icon(Ionicons.trash,color: Colors.red[300],)
                ),
                SizedBox(width: 20,)
              ],
            ),
          ),
          Container(
              width: 310,
              child: Divider(thickness: 1,color: Colors.black,)
          ),
          Row(
            children: [
              SizedBox(
                child: _buildListDevice5(device,device.type),
                width: 360,
                height: 120,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNodeContainer4(Device device) {
    // Your implementation of _buildNodeContainer2 here
    user = FirebaseAuth.instance.currentUser!.email.toString();
    String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');
    return Container(
      width: 320,
      height: 400,
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 70),
      child: Column( // Use Column instead of Row
        children: [
          Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                SizedBox(width: 30,),
                Text("${device.name}", style: TextStyle(color: Colors.black,fontSize: 16,fontWeight: FontWeight.bold),),
                Spacer(),
                IconButton(
                  onPressed: () {
                    _showDeviceInfoDialog(context, device); // Show dialog on button press
                  },
                  icon: Icon(Icons.more_vert, color: Colors.black54),
                ),
                IconButton(
                    onPressed: (){
                      _showDialog(context, device);
                    },
                    icon: Icon(Ionicons.trash,color: Colors.red[300],)
                ),
                SizedBox(width: 20,)
              ],
            ),
          ),
          Container(
              width: 310,
              child: Divider(thickness: 1,color: Colors.black,)
          ),
          Row(
            children: [
              SizedBox(
                child: _buildListDevice4(device,device.type),
                width: 360,
                height: 280,
              ),
            ],
          ),
        ],
      ),
    ); // Example placeholder
  }

  Widget _buildNodeContainer3(Device device) {
    // Your implementation of _buildNodeContainer2 here
    user = FirebaseAuth.instance.currentUser!.email.toString();
    String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');
    return Container(
      width: 320,
      height: 400,
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 70),
      child: Column( // Use Column instead of Row
        children: [
          Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                SizedBox(width: 30,),
                Text("${device.name}", style: TextStyle(color: Colors.black,fontSize: 16,fontWeight: FontWeight.bold),),
                Spacer(),
                IconButton(
                  onPressed: () {
                    _showDeviceInfoDialog(context, device); // Show dialog on button press
                  },
                  icon: Icon(Icons.more_vert, color: Colors.black54),
                ),
                IconButton(
                    onPressed: (){
                      _showDialog(context, device);
                    },
                    icon: Icon(Ionicons.trash,color: Colors.red[300],)
                ),
                SizedBox(width: 20,)
              ],
            ),
          ),
          Container(
              width: 310,
              child: Divider(thickness: 1,color: Colors.black,)
          ),
          Row(
            children: [
              SizedBox(
                child: _buildListDevice3(device,device.type),
                width: 360,
                height: 300,
              ),
            ],
          ),
        ],
      ),
    ); // Example placeholder
  }

  Widget _buildNodeContainer2(Device device) {
    // Your implementation of _buildNodeContainer2 here
    user = FirebaseAuth.instance.currentUser!.email.toString();
    String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');
    return Container(
      width: 320,
      height: 350,
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 70),
      child: Column( // Use Column instead of Row
        children: [
          Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                SizedBox(width: 30,),
                Text("${device.name}", style: TextStyle(color: Colors.black,fontSize: 16,fontWeight: FontWeight.bold),),
                Spacer(),
                IconButton(
                  onPressed: () {
                    _showDeviceInfoDialog(context, device); // Show dialog on button press
                  },
                  icon: Icon(Icons.more_vert, color: Colors.black54),
                ),
                IconButton(
                    onPressed: (){
                      _showDialog(context, device);
                    },
                    icon: Icon(Ionicons.trash,color: Colors.red[300],)
                ),
                SizedBox(width: 20,)
              ],
            ),
          ),
          Container(
              width: 310,
              child: Divider(thickness: 1,color: Colors.black,)
          ),
          Row(
            children: [
              SizedBox(
                child: _buildListDevice2(device,device.type),
                width: 360,
                height: 280,
              ),
            ],
          ),
        ],
      ),
    ); // Example placeholder
  }

  Widget _buildNODEContainer(Device device) {
    // Your implementation of _buildNODEContainer here
    user = FirebaseAuth.instance.currentUser!.email.toString();
    String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');

    // ... (rest of the code)

    return Container(
      width: 320,
      height: 200,
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 70),
      child: Column( // Use Column instead of Row
        children: [
          Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                SizedBox(width: 30,),
                Text("${device.name}", style: TextStyle(color: Colors.black,fontSize: 14,fontWeight: FontWeight.bold),),
                Spacer(),
                IconButton(
                  onPressed: () {
                    _showDeviceInfoDialog(context, device); // Show dialog on button press
                  },
                  icon: Icon(Icons.more_vert, color: Colors.black54),
                ),
                IconButton(
                    onPressed: (){
                      _showDialog(context, device);
                    },
                    icon: Icon(Ionicons.trash,color: Colors.red[300],)
                ),
                SizedBox(width: 20,)
              ],
            ),
          ),
          Container(
              width: 310,
              child: Divider(thickness: 1,color: Colors.black,)
          ),
          Row(
            children: [
              SizedBox(
                child: _buildListDevice(device,device.type),
                width: 360,
                height: 120,
              ),
            ],
          ),
        ],
      ),
    );
  }

  //--------------------------//
  // Build List Device for Node
  //-------------------------//
  ListView _buildListDevice5(Device device, List<Type> types) {
    List<Container> containers = <Container>[];
    for (Type type in types) {
      containers.add(
        Container(
          height: 250,
          child: Row(
            children: [
              Container(
                width: 120,
                height: 150,
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
                      Color(0xFFffffff),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(width: 20,),
                        Text(
                          type.name_u.isEmpty ? "CT_1" : type.name_u,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          onPressed: () {
                            _showEditDialog(device, type);
                          },
                          icon: Icon(Icons.edit, color: Colors.grey[600], size: 20),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(width: 10,),
                        Switch(
                          key: Key(type.value2),
                          value: type.value2 == 'n1',
                          onChanged: (bool newState1) {
                            user = FirebaseAuth.instance.currentUser!.email.toString();
                            String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');
                            String modeString1 = newState1 ? 'n1' : 'f1';
                            setState(() {
                              type.value2 = modeString1;
                            });
                            // Update the state in Firebase
                            df.child("${modifiedUser}").child("DEVICES").child('${device.name}').child("TYPE").child("${type.name}").child("VALUE").set(modeString1);
                            df.child("${modifiedUser}").child("DEVICES").child('${device.name}').child("TYPE").child("${type.name}").child("VALUE2").set(modeString1);
                            df.child("DEVICES").child("${device.name}").child("VALUE").set(modeString1);
                            sendDataToAllUsers(device.name, type.name, modeString1);
                          },
                          activeColor: Colors.blueGrey,
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Ionicons.alarm, color: Colors.black, size: 20),
                          color: Theme.of(context).colorScheme.tertiaryContainer,
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem<String>(
                              value: "On",
                              child: Text("Đặt thời gian bật"),
                            ),
                            PopupMenuItem<String>(
                              value: "Off",
                              child: Text("Đặt thời gian tắt"),
                            ),
                          ],
                          onSelected: (String value) {
                            if (value == "On") {
                              _showTimePickerDialogOff2(device, type);
                            } else if (value == "Off") {
                              _showTimePickerDialogOn2(device, type);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 120,
                height: 150,
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                      Color(0xFFffffff),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(width: 20,),
                        Text(
                          type.name_u2.isEmpty ? "CT_2" : type.name_u2,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          onPressed: () {
                            _showEditDialog2(device, type);
                          },
                          icon: Icon(Icons.edit, color: Colors.grey[600], size: 20),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(width: 10,),
                        Switch(
                          key: Key(type.value3),
                          value: type.value3 == 'n2',
                          onChanged: (bool newState2) {
                            user = FirebaseAuth.instance.currentUser!.email.toString();
                            String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');
                            String modeString2 = newState2 ? 'n2' : 'f2';
                            setState(() {
                              type.value3 = modeString2;
                            });
                            // Update the state in Firebase
                            df.child("${modifiedUser}").child("DEVICES").child('${device.name}').child("TYPE").child("${type.name}").child("VALUE3").set(modeString2);
                            df.child("${modifiedUser}").child("DEVICES").child('${device.name}').child("TYPE").child("${type.name}").child("VALUE").set(modeString2);
                            df.child("DEVICES").child("${device.name}").child("VALUE").set(modeString2);
                            sendDataToAllUsers(device.name, type.name, modeString2);
                          },
                          activeColor: Colors.blueGrey,
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Ionicons.alarm, color: Colors.black, size: 20),
                          color: Theme.of(context).colorScheme.tertiaryContainer,
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem<String>(
                              value: "On",
                              child: Text("Đặt thời gian bật"),
                            ),
                            PopupMenuItem<String>(
                              value: "Off",
                              child: Text("Đặt thời gian tắt"),
                            ),
                          ],
                          onSelected: (String value) {
                            if (value == "On") {
                              _showTimePickerDialogOff3(device, type);
                            } else if (value == "Off") {
                              _showTimePickerDialogOn3(device, type);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 120,
                height: 150,
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                      Color(0xFFffffff),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(width: 20,),
                        Text(
                          type.name_u3.isEmpty ? 'CT_3' : type.name_u3,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          onPressed: () {
                            _showEditDialog3(device, type);
                          },
                          icon: Icon(Icons.edit, color: Colors.grey[600], size: 20),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(width: 10,),
                        Switch(
                          key: Key(type.value4),
                          value: type.value4 == 'n3',
                          onChanged: (bool newState3) {
                            user = FirebaseAuth.instance.currentUser!.email.toString();
                            String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');
                            String modeString3 = newState3 ? 'n3' : 'f3';
                            setState(() {
                              type.value4 = modeString3;
                            });
                            // Update the state in Firebase
                            df.child("${modifiedUser}").child("DEVICES").child('${device.name}').child("TYPE").child("${type.name}").child("VALUE4").set(modeString3);
                            df.child("${modifiedUser}").child("DEVICES").child('${device.name}').child("TYPE").child("${type.name}").child("VALUE").set(modeString3);
                            df.child("DEVICES").child("${device.name}").child("VALUE").set(modeString3);
                            sendDataToAllUsers(device.name, type.name, modeString3);
                          },
                          activeColor: Colors.blueGrey,
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Ionicons.alarm, color: Colors.black, size: 20),
                          color: Theme.of(context).colorScheme.tertiaryContainer,
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem<String>(
                              value: "On",
                              child: Text("Đặt thời gian bật"),
                            ),
                            PopupMenuItem<String>(
                              value: "Off",
                              child: Text("Đặt thời gian tắt"),
                            ),
                          ],
                          onSelected: (String value) {
                            if (value == "On") {
                              _showTimePickerDialogOff4(device, type);
                            } else if (value == "Off") {
                              _showTimePickerDialogOn4(device, type);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        ...containers,
      ],
    );
  }


  ListView _buildListDevice4(Device device, List<Type> types) {
    List<Container> containers = <Container>[];
    for (Type type in types) {
      bool isOn = type.value == 'on';

      containers.add(
        Container(
          width: 320,
          height: 240,
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.grey,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                Color(0xFFffffff),
              ],
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    SizedBox(width: 20,),
                    Text(
                      type.name_u.isEmpty ? type.name : type.name_u,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _showEditDialog(device, type);
                      },
                      icon: Icon(Icons.edit, color: Colors.grey[600], size: 20),
                    ),
                    Spacer(),
                    Column(
                      children: [
                        Text("ON/OFF"),
                        Container(
                          padding: const EdgeInsets.all(4.0),
                          child: Switch(
                            value: isOn,
                            onChanged: (bool newState) {
                              String user = FirebaseAuth.instance.currentUser!.email.toString();
                              String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');
                              String modeString = newState ? 'on' : 'off';
                              setState(() {
                                type.value = modeString;
                              });
                              // Update the state in Firebase
                              df.child("${modifiedUser}").child("DEVICES").child('${device.name}').child("TYPE").child("${type.name}").child("VALUE").set(modeString);
                              df.child("DEVICES").child("${device.name}").child("VALUE").set(modeString);
                            },
                            activeColor: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 20,)
                  ],
                ),
              ),
              Text("Hãy chọn màu RGB",style: TextStyle(fontWeight: FontWeight.bold),),
              // Circular RGB Color Picker
              SizedBox(
                height: 120,
                child: IgnorePointer(
                  ignoring: !isOn, // Disable interaction when OFF
                  child: Opacity(
                    opacity: isOn ? 1.0 : 0.4, // Reduce opacity when OFF
                    child: RGBColorPicker(
                      initialColor: Color.fromRGBO(
                        int.parse(type.value2),
                        int.parse(type.value3),
                        int.parse(type.value4),
                        1,
                      ),
                      onColorChanged: (color) {
                        setState(() {
                          type.value2 = color.red.toString();
                          type.value3 = color.green.toString();
                          type.value4 = color.blue.toString();

                          String user = FirebaseAuth.instance.currentUser!.email.toString();
                          String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');
                          df.child("${modifiedUser}").child("DEVICES").child('${device.name}').child("TYPE").child("${type.name}").child("VALUE2").set(type.value2);
                          df.child("${modifiedUser}").child("DEVICES").child('${device.name}').child("TYPE").child("${type.name}").child("VALUE3").set(type.value3);
                          df.child("${modifiedUser}").child("DEVICES").child('${device.name}').child("TYPE").child("${type.name}").child("VALUE4").set(type.value4);
                        });
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      );
    }

    return ListView(
      scrollDirection: Axis.horizontal,
      children: containers,
    );
  }


  ListView _buildListDevice3(Device device, List<Type> types) {
    List<Container> containers = <Container>[];
    for (Type type in types) {
      containers.add(
        Container(
          width: 320,
          height: 240,  // Adjusted height to accommodate the chart
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.grey,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                Color(0xFFffffff),
              ],
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      type.name_u.isEmpty ? type.name : type.name_u,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Bar chart wrapped in a SizedBox with fixed height
              SizedBox(
                height: 120, // Height for the chart
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: BarChart(
                    BarChartData(
                      maxY: 100,  // Set the maximum Y value to 100
                      barGroups: [
                        BarChartGroupData(
                          x: 0,
                          barsSpace: 20,
                          barRods: [
                            BarChartRodData(
                              toY: double.tryParse(type.value) ?? 0.0,  // Use the value from your data
                              color: Colors.red[300],
                              borderRadius: BorderRadius.circular(4),
                              width: 30,
                            ),
                            BarChartRodData(
                              toY: double.tryParse(type.value2) ?? 0.0,  // Use the value from your data
                              color: Colors.blue[600],
                              borderRadius: BorderRadius.circular(4),
                              width: 30,
                            ),
                            BarChartRodData(
                              toY: double.tryParse(type.value3) ?? 0.0,  // Use the value from your data
                              color: Colors.yellow[800],
                              borderRadius: BorderRadius.circular(4),
                              width: 30,
                            ),
                          ],
                        ),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                ),
                              );
                            },
                            interval: 20,  // Display labels at intervals of 20 (0, 20, 40, 60, 80, 100)
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey,
                            strokeWidth: 0.5,
                          );
                        },
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        children: [
                          Text("Nhiệt độ hiện tại: ${type.value}°C",style: TextStyle(color: Colors.red[300],fontSize: 12,fontWeight: FontWeight.w600),),
                          SizedBox(height: 10,),
                          Text("Độ ẩm hiện tại: ${type.value2}%",style: TextStyle(color: Colors.blue[600],fontSize: 12,fontWeight: FontWeight.w600),),
                          SizedBox(height: 10,),
                          Text("Lượng mưa hiện tại: ${type.value3}%",style: TextStyle(color: Colors.yellow[800],fontSize: 12,fontWeight: FontWeight.w600),),
                          SizedBox(height: 10,),
                          Text("Áp suất hiện tại: ${type.value4}mb",style: TextStyle(color: Colors.green[300],fontSize: 12,fontWeight: FontWeight.w600),),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      scrollDirection: Axis.horizontal,
      children: containers,
    );
  }

  ListView _buildListDevice2(Device device, List<Type> types) {
    List<Container> containers = <Container>[];
    for (Type type in types) {
      containers.add(
        Container(
          width: 260,
          height: 240,  // Adjusted height to accommodate the chart
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.grey,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                Color(0xFFffffff),
              ],
            ),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        SizedBox(width: 20),
                        Text(
                          type.name_u.isEmpty ? type.name : type.name_u,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _showEditDialog(device, type);
                          },
                          icon: Icon(Icons.edit, color: Colors.grey[600], size: 20),
                        ),
                        Spacer(),
                        Container(
                          padding: const EdgeInsets.all(4.0),
                          child: Switch(
                            value: type.value == '1',
                            onChanged: (bool newState) {
                              String user = FirebaseAuth.instance.currentUser!.email.toString();
                              String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');
                              String modeString = newState ? '1' : '0';
                              setState(() {
                                type.value = modeString;
                              });
                              // Update the state in Firebase
                              df.child("${modifiedUser}").child("DEVICES").child('${device.name}').child("TYPE").child("${type.name}").child("VALUE").set(modeString);
                              df.child("DEVICES").child("${device.name}").child("VALUE").set(modeString);
                            },
                            activeColor: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bar chart wrapped in a SizedBox with fixed height
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 130, // Height for the chart
                        width: 80,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: BarChart(
                            BarChartData(
                              maxY: 100,  // Set the maximum Y value to 100
                              barGroups: [
                                BarChartGroupData(
                                  x: 0,
                                  barRods: [
                                    BarChartRodData(
                                      toY: double.tryParse(type.value2) ?? 0.0,  // Use the value from your data
                                      color: Colors.blue[300],
                                      borderRadius: BorderRadius.circular(4),
                                      width: 30,
                                    ),
                                  ],
                                ),
                              ],
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 10,
                                        ),
                                      );
                                    },
                                    interval: 20,  // Display labels at intervals of 20 (0, 20, 40, 60, 80, 100)
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: Colors.grey,
                                    strokeWidth: 0.5,
                                  );
                                },
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(color: Colors.black, width: 1),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Text("Mực nước hiện tại: ${type.value2}%",
                      style: TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              // Positioned alert icon and text at the top-right corner
              if (type.value3 == "1")
                Positioned(
                  top: 120,
                  right: 40,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Ionicons.alert_circle_outline, color: Colors.red, size: 20),
                      Text(
                        "${type.name_u3}",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 6,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );

      if (type.value3 == "1") {
        Noti.showBigTextNotification(
          title: "Cảnh báo khẩn!!!",
          body: "Thiết bị ${device.name} đang gặp sự cố!!!",
          fln: flutterLocalNotificationsPlugin,
          id: 0,
        );
        Notifications notisave = Notifications(
          null,
          "Cảnh báo khẩn!!!",
          "Thiết bị ${device.name} đang gặp sự cố!!!",
          "${formatTime(DateTime.now())}",
        );
        dbHelper.save(notisave);
      }
    }

    return ListView(
      padding: EdgeInsets.all(8),
      children: containers,
    );
  }

  ListView _buildListDevice(Device device, List<Type> types) {
    List<Container> containers = <Container>[];
    for (Type type in types) {
      containers.add(
        Container(
          width: 120,
          height: 50,
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.grey,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                Color(0xFFffffff),
              ],
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      type.name_u.isEmpty ? type.name : type.name_u,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      _showEditDialog(device, type);
                    },
                    icon: Icon(Icons.edit, color: Colors.grey[600], size: 20),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4.0),
                    child: Switch(
                      value: type.value == '1',
                      onChanged: (bool newState) {
                        user = FirebaseAuth.instance.currentUser!.email.toString();
                        String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');
                        String modeString = newState ? '1' : '0';
                        setState(() {
                          type.value = modeString;
                        });
                        // Update the state in Firebase
                        df.child("${modifiedUser}").child("DEVICES").child('${device.name}').child("TYPE").child("${type.name}").child("VALUE").set(modeString);
                        df.child("DEVICES").child("${device.name}").child("VALUE").set(modeString);
                      },
                      activeColor: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        ...containers,
      ],
    );
  }
}

//------END OF WIDGET---------


//------DATA----------

class Device{
  late String id;
  late String name;
  late String ma;
  late String ip_add;
  late List<Type> type;
  Device({
    required this.id,
    required this.name,
    required this.ma,
    required this.ip_add,
    required this.type
  }) ;

  factory Device.fromJson(Map<String, dynamic> json){ //Hàm chuy?n t? json sang d?i tu?ng Device
    List<Type> _type = List.empty(growable: true); //T?o list các d?i tu?ng History
    if ((json['TYPE'] != "") && (json['TYPE'] != null)) {  //N?u json c?a HISTORY có d? li?u
      var historyObjsJson = json['TYPE'] ; //L?y d? li?u json c?a HISTORY
      var historyEncode = jsonEncode(historyObjsJson) ; //Mã hóa thành ki?u json d? x? lí bu?c k?
      final Map parsed = jsonDecode(historyEncode); //Gi?i mã chu?i json này thành m?t list ch?a t?ng d?i tu?ng
      for(final child in parsed.values)  //T?o vòng l?p t?ng d?i tu?ng c?a list trên
          {
        var encodedString = jsonEncode(child);  //Mã hóa thành ki?u json d? x? lí bu?c k?
        Map<String, dynamic> valueMap = jsonDecode(encodedString);  //Gi?i mã chu?i json
        Type user = Type.fromJson(valueMap); //Chuy?n sang d?i tu?ng History
        _type.add(user);
      }
    }
    else {
      _type = [];
    }
    return new Device(
      id: json['ID'],
      name: json['NAME'],
      ma: json['MA'],
      ip_add: json['IP_ADD'],
      type: _type,
    );

  }

  Map toJson() => {  //Hàm chuy?n t? d?i tu?ng Device sang d?ng json
    'ID': id,
    'NAME': name,
    'MA': ma,
    'IP_ADD': ip_add,
    'TYPE': jsonEncode(type)
  };
}

class Type{
  late String value;
  late String value2;
  late String value3;
  late String value4;
  late String name_u;
  late String name_u2;
  late String name_u3;
  late String name;

  Type({required this.value,required this.name_u,required this.name_u2,required this.name_u3,required this.name,required this.value2,required this.value3,required this.value4 });

  factory Type.fromJson(Map<String, dynamic> json) {  //Hàm chuy?n t? json sang d?i tu?ng History
    return Type(
        value:json['VALUE'],
        value2: json['VALUE2'],
        value3: json['VALUE3'],
        value4: json['VALUE4'],
        name_u: json['NAME_U'],
        name_u2: json['NAME_U2'],
        name_u3: json['NAME_U3'],
        name: json["NAME"],
    );
  }

  Map toJson() => {  //Hàm chuy?n t? d?i tu?ng History sang d?ng json
    'VALUE': value,
    'VALUE2': value2,
    'VALUE3': value3,
    'VALUE4': value4,
    'NAME_U': name_u,
    'NAME_U2': name_u2,
    'NAME_U3': name_u3,
    "NAME": name,
  };

  @override
  String toString() {
    return '{ ${this.value},${this.name_u},${this.name_u2},${this.name_u3},${this.name},${this.value2},${this.value3},${this.value4} }';
  }
}

class RGBColorPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  RGBColorPicker({required this.initialColor, required this.onColorChanged});

  @override
  _RGBColorPickerState createState() => _RGBColorPickerState();
}

class _RGBColorPickerState extends State<RGBColorPicker> {
  late Color pickerColor;

  @override
  void initState() {
    super.initState();
    pickerColor = widget.initialColor;
  }

  void changeColor(Color color) {
    setState(() {
      pickerColor = color;
      widget.onColorChanged(color);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
              title: const Text('Hãy chọn màu!'),
              content: SingleChildScrollView(
                child: ColorPicker(
                  pickerColor: pickerColor,
                  onColorChanged: changeColor,
                  showLabel: true,
                  pickerAreaHeightPercent: 0.8,
                ),
              ),
              actions: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: Text('Ok',style: TextStyle(color: Colors.white),),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: pickerColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black),
        ),
      ),
    );
  }
}
