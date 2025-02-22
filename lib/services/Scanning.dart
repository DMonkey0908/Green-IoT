import 'package:demo2/components/Add_new_device.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:web_socket_channel/io.dart';

import '../main.dart';
import 'Noti.dart';
import 'database.dart';
import 'notification.dart';

class Scanning extends StatefulWidget {
  @override
  _ScanningPageState createState() => _ScanningPageState();
}

class _ScanningPageState extends State<Scanning> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin(); //variable notification library
  late Future<List<Notifications>> notisql; //future list notification get from sql
  List<Notifications> notifications = []; //list notification get from sql
  late IOWebSocketChannel _channel; // Khai báo WebSocket dùng trong chương trình
  late bool _connected;
  String? id_room = "";
  String? selectedDeviceName;
  String? device_name_u = '';
  String? selectedRoomId;
  String user = "";
  String id_dv = "ESP32_CT";
  String? device_mode = '';
  int id = 0;
  List<String> deviceNames = [
    'ESP32_CT_1',
    'ESP32_CT_2',
    'ESP32_CT_3',
    'ESP8266_CT_1',
    'ESP8266_CT_2',
    'ESP8266_CT_3',
    'ESP32_SINK',
    'ESP8266_WEATHER',
  ]; // Example device names

  var dbHelper;

  late DatabaseReference df;
  String formatTime(DateTime time) {
    return DateFormat('y MMM EEEE d hh:mm a').format(time);
  }

  String formatTime2(DateTime time){
    return DateFormat('yMMEE').format(time);
  }

  void navigateToAddDevicePage() {
    if (_connected) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddNewDevice()),
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
            title: Text("Lỗi kết nối"),
            content: Text("Không thể kết nối đến thiết bị IoT."),
            actions: <Widget>[
              TextButton(
                child: Text("Đóng"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void initState(){
    super.initState();
    dbHelper = DBHelper();
    Noti.initialize(flutterLocalNotificationsPlugin);
    _connected = false;
    Future.delayed(Duration.zero,() async {
      channelconnect(); // Kết nối với WebSocket khi khởi tạo
    });
  }

  channelconnect(){ // Hàm kết nối WebSocket
    try{
      _channel = IOWebSocketChannel.connect("ws://192.168.0.1:81"); // Kết nối với WebSocket mà ESP32 phát ra
      _channel.stream.listen((message) { // Đọc dữ liệu từ WebSocket mà ESP32 truyền qua
        print(message);
        setState(() {
          if(message == "connected"){
            _connected = true; // Nhận “connected” từ ESP32 qua WebSocket
          }
          // else if (message == "stopped"){
          //
          // }
        });
      },
        onDone: () {
          // Nếu WebSocket mất kết nối
          print("Web socket is closed");
          setState(() {
            _connected = false;
          });
        },
        onError: (error) {
          print(error.toString());
        },);
    }catch (_){
      print("error on connecting to websocket.");
    }
  }

  Future<void> sendcmd(String cmd) async { // Hàm gửi dữ liệu
    if(_connected == true){ // Nếu đang được kết nối WebSocket
      _channel.sink.add(cmd); // Hàm gửi dữ liệu trong thư viện WebSocket
    }else{
      channelconnect();
      print("Websocket is not connected.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Device Setup',style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Container(
        color: Theme.of(context).colorScheme.onPrimaryFixed,
        child: Center(
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  height: 50,
                  child: Row(
                    children: [
                      SizedBox(width: 20,),
                      Text(
                        "Trạng thái kết nối",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _connected ? Colors.green : Colors.red,
                        ),
                      ),
                      SizedBox(width: 120,),
                      Icon(
                        _connected ? Icons.check_circle : Icons.cancel,
                        color: _connected ? Colors.green : Colors.red,
                        size: 24, // Điều chỉnh kích thước của biểu tượng nếu cần
                      ),
                    ],
                  ),
                ),
                Divider(color: Theme.of(context).colorScheme.primary,thickness: 1,),
                SizedBox(height: 30,),
                Text(
                  'Đầu tiên hãy kết nối với thiết bị\nbằng cách kết nối với wifi thiết bị đang phát',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 10.0),
                Text(
                  'Thiết bị đang phát thường có mật khẩu là:\n12345678',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.blue[300],
                  ),
                ),
                SizedBox(height: 15.0),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _connected = false;
                      channelconnect();
                    });
                  },
                  child: Text(
                    'Nếu trạng thái kết nối chưa chuyển sang màu xanh\nhãy bấm vào đây để refresh',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.red,
                    ),
                  ),
                ),
                SizedBox(height: 15.0),
                Text(
                  'Sau khi kết nối thành công hãy\nnhấn nút XÁC NHẬN để thêm thiết bị mới',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Theme.of(context).colorScheme.tertiaryFixed,
                  ),
                ),
                SizedBox(height: 20,),
                ElevatedButton(
                  onPressed: navigateToAddDevicePage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.onPrimary, // background color// text color
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32), // button padding
                  ),
                  child: Text(
                    'Xác nhận',
                    style: TextStyle(
                      fontSize: 20.0,
                      color: Colors.black, // text color
                    ),
                  ),
                ),
                // SizedBox(height: 20,),
                // Text("Hoặc đăng kí thiết bị trực tiếp",style: TextStyle(color: Colors.yellow[800],fontSize: 16),textAlign: TextAlign.center,),
                // Text("(Dành cho các thiết bị đã kết nối Wifi như ESP32_SINK, ESP8266_WEATHER)",textAlign: TextAlign.center,style: TextStyle(color: Colors.black,fontSize: 12),),
                // SizedBox(height: 20,),
                // ElevatedButton(
                //   onPressed: _Dialog_Add_MARINA_Devices,
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Color(0xFF93c47d), // background color// text color
                //     padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32), // button padding
                //   ),
                //   child: Text(
                //     'Đăng kí trực tiếp',
                //     style: TextStyle(
                //       fontSize: 16.0,
                //       color: Colors.black, // text color
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      )
    );
  }
}


