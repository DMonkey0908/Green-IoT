import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';

class DevicesPage extends StatefulWidget {
  final String accountName;

  const DevicesPage({Key? key, required this.accountName}) : super(key: key);

  @override
  _DevicesPageState createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> with SingleTickerProviderStateMixin {
  final DatabaseReference df = FirebaseDatabase.instance.ref();
  String? modifiedUser;
  String? modifiedUser3;
  List<Map<String, dynamic>> devices = [];
  bool isDeleteEnabled = false;

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _fetchDevices();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchDevices() async {
    String user1;
    user1 = FirebaseAuth.instance.currentUser!.email.toString();
    modifiedUser = user1.replaceAll('.', '').replaceAll('@gmail.com', '');
    modifiedUser3 = widget.accountName.replaceAll('.', '').replaceAll('@gmail.com', '');

    DataSnapshot snapshot = await df
        .child(modifiedUser!)
        .child("USERS")
        .child(modifiedUser3!)
        .child("DEVICE")
        .once()
        .then((event) => event.snapshot);

    var deviceData = snapshot.value;

    if (deviceData != null) {
      setState(() {
        devices.clear(); // Clear existing devices
        if (deviceData is Map<dynamic, dynamic>) {
          deviceData.forEach((key, value) {
            devices.add({
              "name": value,
              "checked": false, // Add a checked state for each device
            });
          });
        } else if (deviceData is List) {
          deviceData.asMap().forEach((index, value) {
            devices.add({
              "name": value,
              "checked": false, // Add a checked state for each device
            });
          });
        }
      });
    }
  }

  void _deleteSelectedDevices() {
    List<String> selectedDevices = devices
        .where((device) => device['checked'] == true)
        .map((device) => device['name'].toString())
        .toList();

    // Đặt một Future để xử lý các thao tác xóa và sau đó làm mới giao diện.
    Future.delayed(Duration(milliseconds: 500), () {
      // Làm mới giao diện ngay sau khi thao tác Firebase hoàn tất.
      setState(() {
        _fetchDevices(); // Gọi lại phương thức để tải lại danh sách thiết bị từ Firebase.
      });
    });

    selectedDevices.forEach((device) {
      // Xóa tất cả các giá trị bằng với device trong "DEVICE"
      df.child(modifiedUser!)
          .child("USERS")
          .child(modifiedUser3!)
          .child("DEVICE")
          .orderByValue()
          .equalTo(device)
          .once()
          .then((DatabaseEvent event) {
        // Safely cast the snapshot value to a Map if it's not null
        var values = event.snapshot.value;
        if (values is Map<dynamic, dynamic>) {
          values.forEach((key, value) {
            df.child(modifiedUser!)
                .child("USERS")
                .child(modifiedUser3!)
                .child("DEVICE")
                .child(key)
                .remove();
          });
        }
      });

      // Xóa device trong "DEVICES"
      df.child(modifiedUser3!).child("DEVICES").child(device).remove();
    });
  }


  void _toggleDeleteButton() {
    setState(() {
      isDeleteEnabled = devices.any((device) => device['checked'] == true);
      if (isDeleteEnabled) {
        _controller.forward(); // Play animation when button is enabled
      } else {
        _controller.reverse(); // Reverse animation when button is disabled
      }
    });
  }

  Future<void> _showDeviceListDialog() async {
    List<String> sharedDevices = [];
    List<String> availableDevices = [];

    try {
      // Bước 1: Lấy danh sách document từ DEVICES_SHARED trong Cloud Firestore
      QuerySnapshot firestoreSnapshot =
      await FirebaseFirestore.instance.collection("DEVICES_SHARED").get();

      sharedDevices = firestoreSnapshot.docs
          .map((doc) => doc.id) // Lấy ID của từng document
          .toList();

      // Bước 2: Lấy danh sách các thiết bị từ Firebase Realtime Database
      DataSnapshot snapshot = await df.child(modifiedUser!).child("DEVICES").once().then((event) => event.snapshot);
      var devicesData = snapshot.value;

      if (devicesData != null && devicesData is Map<dynamic, dynamic>) {
        // Lọc danh sách thiết bị dựa trên sharedDevices
        availableDevices = devicesData.keys
            .map((key) => key.toString())
            .where((deviceName) => sharedDevices.any((sharedDevices) => deviceName.contains(sharedDevices)))
            .toList();
      }
    } catch (e) {
      print("Error fetching devices: $e");
    }

    // Hiển thị dialog chọn thiết bị
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          title: Text('Chọn thiết bị'),
          content: availableDevices.isEmpty
              ? Text('Không có thiết bị nào có sẵn.')
              : SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableDevices.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(availableDevices[index]),
                  onTap: () {
                    _addDevice(availableDevices[index]);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Đóng'),
            ),
          ],
        );
      },
    );
  }


  Future<void> _addDevice(String deviceName) async {
    DataSnapshot deviceSnapshot = await df
        .child(modifiedUser!)
        .child("DEVICES")
        .child(deviceName)
        .once()
        .then((event) => event.snapshot);

    if (deviceSnapshot.exists) {
      var deviceData = deviceSnapshot.value;

      if (deviceData != null) {
        // Thêm dữ liệu vào modifiedUser3/DEVICES
        await df.child("$modifiedUser3").child("DEVICES").update({
          deviceName: deviceData,
        });

        // Sinh số ID ngẫu nhiên
        int randomId = Random().nextInt(10000); // Tạo số ID ngẫu nhiên (0-9999)

        // Cập nhật dữ liệu theo định dạng {id: deviceName}
        await df.child("${modifiedUser}")
            .child("USERS")
            .child("$modifiedUser3")
            .child("DEVICE")
            .update({
          "$randomId": deviceName,
        });

        // Cập nhật giá trị NAME trống (nếu cần)
        await df.child("${modifiedUser}")
            .child("USERS")
            .child("$modifiedUser3")
            .child("NAME")
            .set("");

        // Làm mới danh sách thiết bị
        await _fetchDevices();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Text(widget.accountName.isNotEmpty
            ? widget.accountName
            : 'Người dùng chưa xác định',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black
          ),),
      ),
      body: devices.isEmpty
          ? Center(child: Text('Không có thiết bị nào'))
          : Container(
        color: Theme.of(context).colorScheme.onPrimaryFixed,
            child: Column(
                    children: [
            Container(
              width: double.infinity,
              height: 50,
              color: Colors.grey[300],
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  Spacer(),
                  Text(
                    "Số lượng thiết bị đã chia sẻ: ${devices.length}",
                    style: TextStyle(fontSize: 14,fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  Container(
                    height: 35,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)
                          ),
                          backgroundColor: Theme.of(context).colorScheme.onPrimary
                      ),
                      icon: Icon(Icons.add_circle_outlined,color: Colors.black,), // Add icon
                      label: Text('Thêm',style: TextStyle(color: Colors.black,fontSize: 12),),
                      onPressed: () async {
                        await _showDeviceListDialog();
                      },
                    ),
                  ),
                  Spacer(),
                ]
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  return CheckboxListTile(
                    title: Text(device['name'], style: TextStyle(fontSize: 16)),
                    value: device['checked'],
                    onChanged: (bool? value) {
                      setState(() {
                        device['checked'] = value!;
                        _toggleDeleteButton(); // Update delete button state
                      });
                    },
                    controlAffinity: ListTileControlAffinity.platform,
                    checkboxShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50), // Circular shape
                    ),
                    activeColor: Colors.red[300], // Red color for the checkbox
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ScaleTransition(
                scale: _animation,
                child: Visibility(
                  visible: isDeleteEnabled, // Chỉ hiển thị nút khi isDeleteEnabled là true
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, // Màu nút khi có thể xóa
                    ),
                    onPressed: () {
                      _deleteSelectedDevices();
                    },
                    child: Text(
                      'Xóa thiết bị',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
                    ],
                  ),
          ),
    );
  }
}
