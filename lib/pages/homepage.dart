import 'dart:io';

import 'package:demo2/authencation/Account.dart';
import 'package:demo2/services/NotificationProvider.dart';
import 'package:demo2/services/notification.dart';
import 'package:demo2/services/versionchecker2.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ionicons/ionicons.dart';
import 'package:demo2/components/GroupDetails.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/Noti.dart';
import '../services/database.dart';
import 'package:provider/provider.dart';

import '../services/firebase_image_storage.dart';

class Home extends StatefulWidget {
  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> {

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin(); //variable notification library
  late Future<List<Notifications>> notisql; //future list notification get from sql
  List<Notifications> notifications = []; //list notification get from sql

  late DatabaseReference df;
  List<Rooms> _listdv = List.empty(growable: true);
  int id = 0;
  String count = "";
  String? room_name = "";
  String? room_description = "";
  String? room_mode = "";
  String? id_room = "";
  String? dv_count = '';
  String _searchText = "";
  String user = "";

  final TextEditingController _textController = TextEditingController();

  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<String> _imageUrls = [];

  String userAvatarUrl='';
  var dbHelper;

  String formatTime(DateTime time) {
    return DateFormat('y MMM EEEE d hh:mm a').format(time);
  }
  String formatTime2(DateTime time){
    return DateFormat('yMMd').format(time);
  }

  @override
  void deleteRoom(String roomId) {
    df.child("ROOMS").child(roomId).remove();
  }

  void initState() {
    super.initState();
    _loadAvatar();
    Versionchecker2().checkForUpdate(context);
    user = FirebaseAuth.instance.currentUser!.email.toString();
    String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');
    df = FirebaseDatabase.instance.ref(); //Ðây là thu vi?n cu, thu vi?n m?i ta dùng ref()
    df.child("${modifiedUser}").child("ROOMS").onValue.listen((event){ //Ð?c d? li?u t? MACHINES, d? li?u d?c du?c là list json
      List<Rooms> temp = List.empty(growable: true); //T?o m?t list t?o d? luu d? li?u
      //_listdv.clear();
      print( event.snapshot.value.toString() ); //In ra giá tr? d?c du?c ra
      for(final child in event.snapshot.children) //T?o vòng l?p t?ng d?i tuo?ng trong list json d?c du?c ra
          {
        var encodedString = jsonEncode(child.value);  //Mã hóa d? th?c hi?n chuy?n d?i

        Map<String, dynamic> valueMap = json.decode(encodedString);  //Gi?i mã chu?i json

        Rooms user = Rooms.fromJson(valueMap); //Chuy?n d?i sang d?i tu?ng Device
        print(user.id);
        setState(() {
          temp.add(user); //Add t?ng d?i tu?ng vào list t?m
          _listdv.add(user);
        });
        // print(user.history[0].date);
      }
      setState(() {
        _listdv = temp; //Cho list thi?t b? dã khai báo b?ng list t?m
      });
    });
    dbHelper = DBHelper();
    Noti.initialize(flutterLocalNotificationsPlugin);
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('advertisement');
      final ListResult result = await storageRef.listAll();
      final List<String> urls = await Future.wait(
        result.items.map((ref) => ref.getDownloadURL()).toList(),
      );
      setState(() {
        _imageUrls = urls;
      });
      _startImageTimer();
    } catch (e) {
      print('Error fetching images: $e');
    }
  }

  void _startImageTimer() {
    Timer.periodic(Duration(seconds: 10), (Timer timer) {
      if (_currentPage < _imageUrls.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showDialog(BuildContext context, Rooms room) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          title: Text('Xóa phòng'),
          content: Text('Bạn có muốn xóa ${room.name}?'),
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
                if (notificationProvider.isNotificationEnabled) {
                  Noti.showBigTextNotification(
                      title: "Xóa phòng!",
                      body: "Bạn vừa mới xóa ${room.name}",
                      fln: flutterLocalNotificationsPlugin,
                      id: 0
                  );
                }
                Notifications notisave = Notifications(
                    null, "Xóa phòng", "Bạn vừa mới xóa ${room.name}", "${formatTime(DateTime.now())}");
                dbHelper.save(notisave);
                user = FirebaseAuth.instance.currentUser!.email.toString();
                String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');
                deleteRoom(room.name);
                df.child(modifiedUser).child("ROOMS").child("${room.id}").remove();
                setState(() {
                  _listdv.remove(room);
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

  final FirebaseImageStorage _firebaseImageStorage = FirebaseImageStorage();
  File? _localAvatarFile;

  /// Tải và hiển thị ảnh từ bộ nhớ cục bộ hoặc từ Firebase Storage
  Future<void> _loadAvatar() async {
    final file = await _firebaseImageStorage.getOrDownloadAvatar();
    setState(() {
      _localAvatarFile = file;
    });
  }


  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
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
                height: 725,
                width: 600,
                child: Stack(
                  children: [
                    Positioned(
                      top: 290,
                      left: (MediaQuery.of(context).size.width - 460) / 2,
                      bottom: 0.5,
                      child: SizedBox(
                        // margin: EdgeInsets.only(top: 180),
                        width: 460,
                        child: _buldListDevice(_listdv),
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
                                  hintText: 'Tìm kiếm phòng',
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
                                      });
                                    },
                                  )
                                      : null,
                                ),
                              ),
                            ),
                            SizedBox(width: 3,),
                            IconButton(
                              onPressed: (){
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => Nofication()),
                                );
                              },
                              icon: Icon(Ionicons.notifications,color: Colors.white,size: 25,),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 98),
                      height: 170,
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _imageUrls.length,
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            // borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _imageUrls[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 130,
                            ),
                          );
                        },
                      )
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 268),
                      height: 50,
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: Row(
                        children: [
                          SizedBox(width: 20.0),
                          Text(
                            "Số phòng hiện có: ${_listdv.length}",
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
                              label: Text('Thêm phòng',style: TextStyle(color: Colors.black,fontSize: 12),),
                              onPressed: () {
                                // Your "thêm phòng" functionality here
                                _Dialog_Add_Room();
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

  Container _buildRoomContainer(Rooms room) {
    // Hàm xác định đường dẫn ảnh dựa trên tên phòng
    String getBackgroundImage(String roomName) {
      if (roomName.contains("khách")) return "assets/images/rooms/1.jpg";
      if (roomName.contains("họp")) return "assets/images/rooms/2.jpg";
      if (roomName.contains("ngủ")) return "assets/images/rooms/3.jpg";
      if (roomName.contains("sân")) return "assets/images/rooms/4.jpg";
      if (roomName.contains("hầm")) return "assets/images/rooms/5.jpg";
      if (roomName.contains("thượng")) return "assets/images/rooms/6.jpg";
      if (roomName.contains("bếp")) return "assets/images/rooms/8.jpg";
      if (roomName.contains("nghiên cứu") || roomName.contains("lab")) return "assets/images/rooms/9.jpg";
      if (roomName.contains("game")) return "assets/images/rooms/10.jpg";
      return "assets/images/rooms/7.jpg";
    }

    String backgroundImage = getBackgroundImage(room.name.toLowerCase());

    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 70),
      height: 120,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Groupdetails(
                roomID: room.id,
                roomName: room.name,
                DeviceCount: room.devices.length,
                id_room: room.id,
              ),
            ),
          );
        },
        child: Stack(
          children: [
            // Hình nền
            Positioned.fill(
              child: Opacity(
                opacity: 0.3, // Độ mờ của hình ảnh
                child: Image.asset(
                  backgroundImage,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Nội dung bên trên hình nền
            Container(
              // decoration: BoxDecoration(
              //   borderRadius: BorderRadius.circular(10),
              //   gradient: LinearGradient(
              //     begin: Alignment.topLeft,
              //     end: Alignment.bottomRight,
              //     colors: [
              //       Theme.of(context)
              //           .colorScheme
              //           .primaryContainer
              //           .withOpacity(0.8),
              //       Colors.white,
              //     ],
              //   ),
              //   boxShadow: [
              //     BoxShadow(
              //       color: Colors.grey,
              //       blurRadius: 10,
              //       offset: Offset(0, 5),
              //     ),
              //   ],
              // ),
              child: Row(
                children: [
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 15),
                      Text(
                        '${room.name}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primaryFixed,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        '${room.description.isEmpty ? 'Chưa có mô tả' : room.description}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.secondaryFixed,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'Thiết bị hiện có: ${room.device_count}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onPrimaryFixedVariant,
                          fontWeight: FontWeight.w600
                        ),
                      ),
                    ],
                  ),
                  Spacer(flex: 1),
                  Column(
                    children: [
                      SizedBox(height: 3),
                      IconButton(
                        onPressed: () {
                          _showEditDialog(room);
                        },
                        icon: Icon(
                          BoxIcons.bxs_pencil,
                          color: Theme.of(context).colorScheme.secondaryFixedDim,
                          size: 20,
                        ),
                      ),
                      SizedBox(height: 10),
                      IconButton(
                        onPressed: () {
                          _showDialog(context, room);
                        },
                        icon: Icon(
                          Ionicons.trash,
                          color: Colors.red[500],
                          size: 20,
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                  SizedBox(width: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ListView _buldListDevice(List<Rooms> rooms) {//ListView t? danh sách Device
    List<Container> containers = rooms  //T?o list các container
      .where((room)=> room.name.toLowerCase().contains(_searchText.toLowerCase()))
      .map((room)=> _buildRoomContainer(room))
      .toList();
    return ListView(  //Tr? l?i giá tr? ListView
      children: [
        ...containers, //Ð?t list các container vào
      ],
    );
  }

  Future<void> _showEditDialog(Rooms room) async {
    String? roomName = room.name;
    String? roomDescription = room.description;
    user = FirebaseAuth.instance.currentUser!.email.toString();
    String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');

    // Tạo các TextEditingController bên ngoài StatefulBuilder
    TextEditingController roomNameController = TextEditingController(text: roomName);
    TextEditingController roomDescriptionController = TextEditingController(text: roomDescription);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          title: Text('Chỉnh sửa phòng'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    cursorColor: Colors.black,
                    onChanged: (value) {
                      setState(() {
                        roomName = value;
                      });
                    },
                    controller: roomNameController,
                    decoration: InputDecoration(
                      labelText: 'Tên phòng',
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface,),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.onSurface,
                        )
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.onSurface,
                        )
                      )
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    cursorColor: Colors.black,
                    onChanged: (value) {
                      setState(() {
                        roomDescription = value;
                      });
                    },
                    controller: roomDescriptionController,
                    decoration: InputDecoration(
                      labelText: 'Mô tả',
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface,),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.onSurface,
                        )
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.onSurface,
                        )
                      )
                    ),
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Hủy'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.grey.withOpacity(0.4),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Lưu'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.6),
              ),
              onPressed: () {
                setState(() {
                  room.name = roomName!;
                  room.description = roomDescription!;
                });

                df.child("${modifiedUser}").child("ROOMS").child("${room.id}").child("NAME").set("$roomName");
                df.child("${modifiedUser}").child("ROOMS").child("${room.id}").child("DESCRIPTION").set("$roomDescription");

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }



  Future _Dialog_Add_Room() => showDialog( //Dialog thêm Room
      context: context,
      builder: (context) {
        room_name = "";
        room_description = "";
        id++;
        id_room = "${id}_${formatTime2(DateTime.now())}";
        room_mode = 'manual';
        user = FirebaseAuth.instance.currentUser!.email.toString();
        String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');
        double width = MediaQuery.of(context).size.width; //360
        double height = MediaQuery.of(context).size.height; //715
        return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
            content: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Container(
                      height: 255,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children:[
                            Text("Thêm Phòng",style:TextStyle(color: Theme.of(context).colorScheme.surfaceTint,fontWeight: FontWeight.bold,fontSize:18)),
                            SizedBox(height: 5),
                            Container(  //Nh?p id cho thi?t b?
                                height: 45,
                                child:  TextFormField(
                                  maxLength: 20,
                                  cursorColor: Colors.black,
                                  controller: new TextEditingController.fromValue(new TextEditingValue(text: room_name.toString(),selection: new TextSelection.collapsed(offset: room_name.toString().length))),
                                  onChanged: (value) => room_name = value,
                                  decoration:  InputDecoration(
                                      counterText: '',
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.black.withOpacity(0.7)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.black.withOpacity(0.7)),
                                      ),
                                      filled: false,
                                      // hintText: 'Enter name of patient',
                                      hintStyle:  TextStyle(color: Colors.grey.shade500, fontSize: 12.0,

                                      ),
                                      border: OutlineInputBorder(),
                                      labelText: 'Tên phòng',
                                      labelStyle: TextStyle(color: Colors.black.withOpacity(0.7),fontSize: 14)
                                  ),
                                )),
                            SizedBox(height: 0,),
                            Container( //Nh?p sdd thi?t b?
                                height: 45,
                                child:  TextFormField(
                                  maxLength: 30,
                                  cursorColor: Colors.black,
                                  controller: new TextEditingController.fromValue(new TextEditingValue(text: room_description.toString(),selection: new TextSelection.collapsed(offset: room_description.toString().length))),
                                  onChanged: (value) => room_description = value,
                                  decoration:  InputDecoration(
                                      counterText: '',
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.black.withOpacity(0.7)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.black.withOpacity(0.7)),
                                      ),
                                      filled: false,
                                      // hintText: 'Enter name of patient',
                                      hintStyle:  TextStyle(color: Colors.grey.shade500, fontSize: 12.0,

                                      ),
                                      border: OutlineInputBorder(),
                                      labelText: 'Mô tả',
                                      labelStyle: TextStyle(color: Colors.black.withOpacity(0.7),fontSize: 14)
                                  ),
                                )),
                            SizedBox(height: 10,),
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.spaceBetween
                            // ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  onPressed: (){
                                    room_description = "";
                                    room_name = "";
                                    room_mode = 'manual';
                                    Navigator.of(context).pop();
                                  },

                                  child: Text("Ðóng",style:TextStyle(color: Colors.white.withOpacity(1),fontSize: 14,fontWeight: FontWeight.bold),),style: ElevatedButton.styleFrom(shape: BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),fixedSize: Size(110, 40),backgroundColor: Colors.grey.withOpacity(0.4)),),
                                SizedBox(width:5*width/384),
                                ElevatedButton(
                                  onPressed: () async{
                                    final notificationProvider = Provider.of<NotificationProvider>(context,listen: false);
                                    if (notificationProvider.isNotificationEnabled) {
                                      Noti.showBigTextNotification(
                                          title: "Thêm phòng mới!",
                                          body: "Bạn vừa mới thêm $room_name",
                                          fln: flutterLocalNotificationsPlugin,
                                          id: 0
                                      );
                                    }
                                    Notifications notisave = Notifications(
                                        null, "Thêm phòng mới", "Bạn vừa mới thêm $room_name", "${formatTime(DateTime.now())}");
                                    dbHelper.save(notisave);
                                    //Khi nh?n nút thêm s? t?o các tru?ng trên firebase
                                    df.child("${modifiedUser}").child("ROOMS").child("${id_room}").child("ID").set("$id_room");
                                    df.child("${modifiedUser}").child("ROOMS").child("${id_room}").child("NAME").set("$room_name");
                                    df.child("${modifiedUser}").child("ROOMS").child("${id_room}").child("DESCRIPTION").set("$room_description");
                                    df.child("${modifiedUser}").child("ROOMS").child("${id_room}").child("MODE").set("$room_mode");
                                    df.child("${modifiedUser}").child("ROOMS").child("${id_room}").child("DEVICE_COUNT").set("$dv_count");
                                    Navigator.of(context).pop();
                                  },
                                  child: Text("Thêm",style:TextStyle(color: Colors.white,fontSize: 14,fontWeight: FontWeight.bold),),style: ElevatedButton.styleFrom(shape: BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),fixedSize: Size(110, 40),backgroundColor: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.6)),),
                              ],
                            )
                          ]
                      )
                  );
                }
            )
        );}
  );
}

class Rooms{
  late String id;
  late String name;
  late String description;
  late String mode;
  late String device_count;
  late List<Devices> devices;
  Rooms({
    required this.id,
    required this.name,
    required this.description,
    required this.mode,
    required this.device_count,
    required this.devices
  }) ;

  factory Rooms.fromJson(Map<String, dynamic> json){ //Hàm chuyển từ json sang đối tượng Device
    List<Devices> _devices = List.empty(growable: true); //Tạo list các đối tượng
    if ((json['DEVICES'] != "") && (json['DEVICES'] != null)) {  // Kiểm tra dữ liệu có không?
      var historyObjsJson = json['DEVICES'] ; //Lấy dữ liệu json
      var historyEncode = jsonEncode(historyObjsJson) ; //Mã hóa thành kiểu json để xử lí bước tiếp theo
      final Map parsed = jsonDecode(historyEncode); //Giải mã chuỗi json này thành một list chứa từng đối tượng
      for(final child in parsed.values)  // lặp từng đối tượng của list trên
          {
        var encodedString = jsonEncode(child);  //Mã hóa thành ki?u json d? x? lí bu?c k?
        Map<String, dynamic> valueMap = jsonDecode(encodedString);  //Gi?i mã chu?i json
        Devices user = Devices.fromJson(valueMap); //Chuy?n sang d?i tu?ng History
        _devices.add(user);
      }
    }
    else {
      _devices = [];
    }
    return new Rooms(
      id: json['ID'],
      name: json['NAME'],
      description: json['DESCRIPTION'],
      mode: json['MODE'],
      device_count: json['DEVICE_COUNT'],
      devices: _devices,
    );

  }

  Map toJson() => {  //Hàm chuy?n t? d?i tu?ng Device sang d?ng json
    'ID': id,
    'NAME': name,
    'DESCRIPTION': description,
    'MODE': mode,
    'DEVICE_COUNT': device_count,
    'DEVICES': jsonEncode(devices)
  };
}

class Devices{
  late String id;
  late String name;

  Devices({required this.id, required this.name});

  factory Devices.fromJson(Map<String, dynamic> json) {  //Hàm chuy?n t? json sang d?i tu?ng History
    return Devices(
        id:json['ID'] ,
        name:json['NAME'] );
  }

  Map toJson() => {  //Hàm chuy?n t? d?i tu?ng History sang d?ng json
    'ID': id,
    '': name,
  };

  @override
  String toString() {
    return '{ ${this.id}, ${this.name} }';
  }
}
