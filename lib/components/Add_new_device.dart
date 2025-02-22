import 'package:demo2/services/wifi_storage.dart';
import 'package:demo2/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:web_socket_channel/io.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/Noti.dart';
import '../services/NotificationProvider.dart';
import '../services/database.dart';
import '../services/notification.dart';

class AddNewDevice extends StatefulWidget{
  @override
  State<AddNewDevice> createState() => AddNewDeviceState();
}
class AddNewDeviceState extends State<AddNewDevice> with SingleTickerProviderStateMixin {

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin(); //variable notification library
  late Future<List<Notifications>> notisql; //future list notification get from sql
  List<Notifications> notifications = []; //list notification get from sql

  late DatabaseReference df2;

  int id = 0;
  String? _ssid_config = "";
  String? _pass_config = "";
  bool _showpass_config = true;
  String? device_name_u = '';
  String? id_room = "";
  String? device_mode = '';

  String? selectedRoomId;
  String? selectedDeviceName;
  String user = "";
  String id_dv = "ESP32_CT";

  var dbHelper;

  late IOWebSocketChannel _channel; // Khai báo WebSocket dùng trong chương trình
  late bool _connected; // Biến kiếm tra tình trạng kết nối WebSocket
  late DatabaseReference df;

  String formatTime(DateTime time) {
    return DateFormat('y MMM EEEE d hh:mm a').format(time);
  }

  String formatTime2(DateTime time){
    return DateFormat('dd/MM/yyyy').format(time);
  }

  void _showSavedWiFiDialog() async {
    List<Map<String, String>> savedWiFiList = await WiFiStorage.getWiFiList();

    // Loại bỏ các phần tử trùng lặp bằng cách sử dụng Set
    List<Map<String, String>> uniqueWiFiList = [];
    Set<String> seenWiFi = Set(); // Set để lưu trữ các cặp SSID và Password đã thấy

    for (var wifi in savedWiFiList) {
      String ssid = wifi['SSID']!;
      String password = wifi['Password']!;
      String key = ssid + password; // Tạo khóa duy nhất từ SSID và Password

      if (!seenWiFi.contains(key)) {
        seenWiFi.add(key); // Nếu chưa có trong Set, thêm vào
        uniqueWiFiList.add(wifi); // Thêm WiFi vào danh sách duy nhất
      }
    }

    // Hiển thị dialog với danh sách WiFi duy nhất
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: 300,
              maxWidth: 300,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Chọn WiFi đã lưu",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16,color: Colors.black)),
                Divider(
                  thickness: 2,
                ),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: uniqueWiFiList.length,
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        title: Text(uniqueWiFiList[index]['SSID']!),
                        onTap: () {
                          setState(() {
                            _ssid_config = uniqueWiFiList[index]['SSID'];
                            _pass_config = uniqueWiFiList[index]['Password'];
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  late AnimationController _controller;

  @override
  void initState(){
    super.initState();
    dbHelper = DBHelper();
    Noti.initialize(flutterLocalNotificationsPlugin);
    _connected = false;
    Future.delayed(Duration.zero,() async {
      channelconnect(); // Kết nối với WebSocket khi khởi tạo
    });
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true); // Lặp animation
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Không cho phép đóng dialog bằng cách nhấn ra ngoài
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          title: Text("Đang xử lý"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("Vui lòng đợi trong giây lát..."),
              ],
            ),
          ),
        );
      },
    );
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
  Widget build(BuildContext context){
    device_mode = '0';
    id++;
    id.toString();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Text(
          'Kết nối Node IoT',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              SizedBox(height: 50,),
              GestureDetector(
                onTap: (){
                  channelconnect();
                },
                child: Container(
                  width: 280,
                  height: 250,
                  child: Column(
                    children: [
                      Text("Kết nối thiết bị vào mạng nội bộ", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),),
                      SizedBox(height: 10,),
                      Text("Nhập tên Wifi và mật khẩu mạng nội bộ để tiến hành đăng kí kết nối thiết bị vào mạng nội bộ", style: TextStyle(fontSize: 14,color: Colors.blue),),
                      SizedBox(height: 30,),
                      Row(
                        children: [
                          Icon(Ionicons.hardware_chip,size: 90,color: Theme.of(context).colorScheme.surfaceTint,),
                          SizedBox(width: 20,),
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              int wifiLevel = ((_controller.value * 3).ceil()).clamp(1, 3);
                              IconData wifiIcon = Icons.wifi_1_bar;
                              if (wifiLevel == 2) wifiIcon = Icons.wifi_2_bar;
                              if (wifiLevel == 3) wifiIcon = Icons.wifi;

                              return Transform.rotate(
                                angle: 90 * 3.14159265359 / 180,
                                child: Icon(
                                  wifiIcon,
                                  size: 60,
                                  color: Colors.blue,
                                ),
                              );
                            },
                          ),
                          SizedBox(width: 20,),
                          Icon(Icons.router,size: 90,color: Theme.of(context).colorScheme.surfaceTint,),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10,),
              Container(
                height: 50,
                width: 280,
                decoration: BoxDecoration(
                  color: Color(0xFFeeeeee),
                  borderRadius: BorderRadius.all(
                      Radius.circular(6)
                  ),
                  // border: Border.all(
                  //   color: Color(0xFFFFFFFF),
                  // ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width:220,
                      height: 40,
                      child: Padding(
                        padding:  EdgeInsets.fromLTRB(15, 15, 0, 0),
                        child: TextFormField(
                          cursorColor: Colors.black,
                          onChanged: (value) => _ssid_config = value,
                          style: TextStyle(color: Colors.black,fontSize: 13),
                          controller: new TextEditingController.fromValue(new TextEditingValue(text: _ssid_config.toString(),selection: new TextSelection.collapsed(offset: _ssid_config.toString().length))),
                          decoration:  InputDecoration(
                              enabledBorder:  OutlineInputBorder(
                                // width: 0.0 produces a thin "hairline" border
                                borderSide:  BorderSide(color: Color(0x00474234),),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0x00474234),),
                              ),

                              hintText: "Nhập tên WIFI",
                              hintStyle: TextStyle(color: Colors.black,fontSize: 13) //0x80E91E63
                          ),
                          // obscureText:_showpass_config,
                        ),
                      ),
                    ),
                    Container(
                      height: 60,
                      width: 60,
                      // padding:  EdgeInsets.fromLTRB(0, 0, 0, 50),
                      child: IconButton(
                        onPressed: (){
                          setState(() {
                            _showSavedWiFiDialog();
                          });
                        },
                        color: Colors.black,
                        icon: Icon(Icons.wifi_lock_outlined),),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 5,),
              Container(
                height: 50,
                width: 280,
                decoration: BoxDecoration(
                  color: Color(0xFFeeeeee),
                  borderRadius: BorderRadius.all(
                      Radius.circular(6)
                  ),
                  // border: Border.all(
                  //   color: Color(0xFFFFFFFF),
                  // ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width:220,
                      height: 40,
                      child: Padding(
                        padding:  EdgeInsets.fromLTRB(15, 15, 0, 0),
                        child: TextFormField(
                          cursorColor: Colors.black,
                          onChanged: (value) => _pass_config = value,
                          style: TextStyle(color: Colors.black,fontSize: 13),
                          controller: new TextEditingController.fromValue(new TextEditingValue(text: _pass_config.toString(),selection: new TextSelection.collapsed(offset: _pass_config.toString().length))),
                          decoration:  InputDecoration(
                              enabledBorder:  OutlineInputBorder(
                                // width: 0.0 produces a thin "hairline" border
                                borderSide:  BorderSide(color: Color(0x00474234),),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0x00474234),),
                              ),
                              hintText: "Nhập mật khẩu",
                              hintStyle: TextStyle(color: Colors.black,fontSize: 13) //0x80E91E63
                          ),
                          obscureText:_showpass_config,
                        ),
                      ),
                    ),
                    Container(
                      height: 60,
                      width: 60,
                      // padding:  EdgeInsets.fromLTRB(0, 0, 0, 50),
                      child: IconButton(
                        onPressed: (){
                          setState(() {
                            _showpass_config = !_showpass_config;
                          });
                        },
                        color: Colors.black,
                        icon: Icon(!_showpass_config?Icons.remove_red_eye:Icons.remove_red_eye_outlined,size: 15),),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              GestureDetector(//Nút nhấn xác nhận gửi dữ liệu
                onTap: () async {
                  if (_connected) {
                    final notificationProvider = Provider.of<NotificationProvider>(context,listen: false);
                    user = FirebaseAuth.instance.currentUser!.email.toString();
                    String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');

                    // Save WiFi credentials to storage
                    await WiFiStorage.addWiFi(_ssid_config.toString(), _pass_config.toString());

                    sendcmd("{\"USER\":\"${modifiedUser}\",\"SSID\":\"${_ssid_config.toString()}\",\"PSSD\":\"${_pass_config.toString()}\"}");
                    _showLoadingDialog(); // Hiển thị dialog loading
                    // Đợi 5 giây trước khi đóng dialog và hiển thị dialog thứ hai
                    await Future.delayed(Duration(seconds: 5));
                    Navigator.of(context).pop(); // Đóng dialog loading
                    if (notificationProvider.isNotificationEnabled) {
                      Noti.showBigTextNotification(
                          title: "Đăng kí thiết bị!",
                          body: "Bạn vừa mới đăng kí thiết bị mới",
                          fln: flutterLocalNotificationsPlugin,
                          id: id
                      );
                    }
                    Notifications notisave = Notifications(
                        null,
                        "Đăng kí thiết bị",
                        "Bạn vừa đăng kí thiết bị mới",
                        "${formatTime(DateTime.now())}"
                    );
                    dbHelper.save(notisave);
                    // _Dialog_Add_MARINA_Devices();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyHomePage(title: '',)),
                    );
                  }
                },
                child: Container(
                  width: 280,
                  height: 40,
                  decoration: BoxDecoration(
                      gradient:
                      LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors:
                          [
                            // Color(0xFFF5CB5C),
                            Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                            Color(0xFFffffff),
                          ]
                      ),
                      // image: DecorationImage(image: AssetImage("assets/bien2.jpg",),fit: BoxFit.fill,opacity: 0.5),
                      borderRadius: BorderRadius.circular(10)
                  ),
                  child:
                  Center(child: Text("Xác nhận",style: TextStyle(color: Colors.black12.withOpacity(1),fontSize: 17,fontWeight: FontWeight.bold),)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}