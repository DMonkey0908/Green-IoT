import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo2/services/users_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';

class ShareDb extends StatefulWidget {
  @override
  ShareDbState createState() => ShareDbState();
}

class ShareDbState extends State<ShareDb> {
  final _formKey = GlobalKey<FormState>();
  final _destinationEmailController = TextEditingController();

  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  String user = "";
  late DatabaseReference df;
  List<String> selectedDevices = [];

  @override
  void initState() {
    super.initState();
    df = FirebaseDatabase.instance.ref();
  }

  Future<void> _showDeviceSelectionDialog(String sourceEmail) async {
    List<String> sharedDevicesFromFirestore = [];
    List<String> deviceNames = [];
    List<bool> isSelected;

    try {
      // Bước 1: Lấy danh sách từ Firestore
      QuerySnapshot firestoreSnapshot = await FirebaseFirestore.instance.collection("DEVICES_SHARED").get();
      sharedDevicesFromFirestore = firestoreSnapshot.docs.map((doc) => doc.id).toList();

      // Bước 2: Lấy danh sách thiết bị từ Firebase Realtime Database
      DatabaseReference devicesRef = _databaseRef.child(sourceEmail).child('DEVICES');
      DataSnapshot snapshot = await devicesRef.get();

      if (snapshot.exists) {
        Map<String, dynamic> devices = Map<String, dynamic>.from(snapshot.value as Map);

        // Bước 3: Lấy danh sách các thiết bị đã chia sẻ với destination user
        String destinationEmail = _destinationEmailController.text;
        String modifiedUser2 = destinationEmail.replaceAll('.', '').replaceAll('@gmail.com', '');
        DataSnapshot sharedDevicesSnapshot = await df
            .child("${sourceEmail}")
            .child("USERS")
            .child("$modifiedUser2")
            .child("DEVICE")
            .get();

        List<String> sharedDevices = [];
        if (sharedDevicesSnapshot.exists) {
          sharedDevices = List<String>.from(sharedDevicesSnapshot.value as List);
        }

        // Bước 4: Lọc danh sách thiết bị với điều kiện chứa chuỗi từ DEVICES_SHARED
        deviceNames = devices.keys
            .where((deviceName) => sharedDevicesFromFirestore.any((sharedDevice) => deviceName.contains(sharedDevice)) && // Tên chứa chuỗi từ Firestore
            !sharedDevices.contains(deviceName)) // Chưa chia sẻ với destination user
            .toList();

        isSelected = List.filled(deviceNames.length, false);

        // Hiển thị dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                  title: Text('Chọn thiết bị để chia sẻ'),
                  content: Container(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: deviceNames.length,
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            CheckboxListTile(
                              title: Text(deviceNames[index],
                                  style: TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w600)),
                              value: isSelected[index],
                              onChanged: (bool? value) {
                                setState(() {
                                  isSelected[index] = value ?? false;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              checkboxShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              activeColor: Colors.green[400],
                            ),
                            Divider(
                              thickness: 2,
                              indent: 25,
                              endIndent: 20,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        selectedDevices = [];
                        for (int i = 0; i < deviceNames.length; i++) {
                          if (isSelected[i]) {
                            selectedDevices.add(deviceNames[i]);
                          }
                        }
                        Navigator.of(context).pop();
                        copySelectedData(selectedDevices);
                      },
                      child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onPrimary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('OK',
                              style: TextStyle(color: Colors.white))),
                    ),
                  ],
                );
              },
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tìm thấy thiết bị nào.',style: TextStyle(color: Colors.white),)),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xảy ra lỗi khi lấy danh sách thiết bị.',style: TextStyle(color: Colors.white),)),
      );
    }
  }

  Future<void> copySelectedData(List<String> selectedDevices) async {
    user = FirebaseAuth.instance.currentUser!.email.toString();
    if (_formKey.currentState!.validate()) {
      String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');
      String destinationEmail = _destinationEmailController.text;
      String modifiedUser2 = destinationEmail.replaceAll('.', '').replaceAll('@gmail.com', '');

      try {
        // Lấy dữ liệu từ người dùng nguồn
        DatabaseReference sourceRef = _databaseRef.child(modifiedUser);
        DataSnapshot snapshot = await sourceRef.get();

        if (!snapshot.exists || snapshot.value == null) {
          throw 'Không tìm thấy dữ liệu nguồn.';
        }

        // Kiểm tra và chuyển đổi dữ liệu nguồn
        Map<String, dynamic> data = {};
        if (snapshot.value is Map) {
          data = Map<String, dynamic>.from(snapshot.value as Map);
        } else {
          print('Dữ liệu từ Firebase không phải là Map: ${snapshot.value}');
          throw 'Dữ liệu không hợp lệ.';
        }

        // Kiểm tra key 'DEVICES'
        if (data['DEVICES'] == null || data['DEVICES'] is! Map) {
          print('DEVICES không phải là Map hoặc không tồn tại: ${data['DEVICES']}');
          throw 'Dữ liệu nguồn không có mục DEVICES hợp lệ.';
        }

        Map<String, dynamic> devicesData = Map<String, dynamic>.from(data['DEVICES'] as Map);

        // Lọc dữ liệu đã chọn
        Map<String, dynamic> selectedData = {};
        for (String device in selectedDevices) {
          if (devicesData[device] != null) {
            selectedData[device] = devicesData[device];
          } else {
            print('Thiết bị $device không tồn tại trong dữ liệu nguồn.');
          }
        }

        // Lấy dữ liệu hiện có của người dùng đích
        DatabaseReference destinationRef = _databaseRef.child(modifiedUser2);
        DataSnapshot destinationSnapshot = await destinationRef.get();

        if (destinationSnapshot.exists) {
          // Lấy dữ liệu DEVICES hiện có
          DatabaseReference devicesRef = destinationRef.child('DEVICES');
          DataSnapshot devicesSnapshot = await devicesRef.get();

          Map<String, dynamic> existingDevices = {};
          if (devicesSnapshot.exists && devicesSnapshot.value != null) {
            if (devicesSnapshot.value is Map) {
              existingDevices = Map<String, dynamic>.from(devicesSnapshot.value as Map);
            } else {
              print('Dữ liệu DEVICES hiện có không phải là Map: ${devicesSnapshot.value}');
            }
          }

          // Kết hợp dữ liệu
          Map<String, dynamic> updatedDevices = {...existingDevices, ...selectedData};

          // Cập nhật DEVICES
          await devicesRef.update(updatedDevices);

          // Cập nhật các trường khác
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chia sẻ dữ liệu thành công!')),
          );

          df.child("${modifiedUser}").child("USERS").child("$modifiedUser2").child("EMAIL").set(destinationEmail);
          Map<String, String> devicesToUpdate = {};
          final random = Random();

          // Tạo các trường với key là số ngẫu nhiên 4 chữ số và value là tên thiết bị
          for (String device in selectedDevices) {
            String randomKey;
            do {
              randomKey = random.nextInt(9000 + 1000).toString(); // Tạo số ngẫu nhiên 4 chữ số
            } while (devicesToUpdate.containsKey(randomKey)); // Đảm bảo không trùng key
            devicesToUpdate[randomKey] = device;
          }

          // Cập nhật dữ liệu vào Firebase
          await df
              .child("${modifiedUser}")
              .child("USERS")
              .child("$modifiedUser2")
              .child("DEVICE")
              .set(devicesToUpdate);
          df.child("${modifiedUser}").child("USERS").child("$modifiedUser2").child("NAME").set("");

          for (String device in selectedDevices) {
            df.child("DEVICES").child(device).child("VALUE").set("0");
          }

          await FirebaseFirestore.instance.collection('FAMILY').doc(modifiedUser2).set({
            'EMAIL': user,
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không có người dùng này trên hệ thống.',style: TextStyle(color: Colors.white),)),
          );
        }
      } catch (error) {
        print('Lỗi khi chia sẻ dữ liệu: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chia sẻ dữ liệu thất bại!',style: TextStyle(color: Colors.white),)),
        );
      }
    }
  }

  void _showEmptyEmailDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          title: Text('Thông báo'),
          content: Text('Hãy nhập email mà bạn muốn chia sẻ'),
          actions: <Widget>[
            TextButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                foregroundColor: Colors.white,
              ),
              child: Text('Đóng'),
              onPressed: () {
                Navigator.of(context).pop(); // Đóng Dialog
              },
            ),
          ],
        );
      },
    );
  }

  void _onConfirmPressed() {
    if (_destinationEmailController.text.isEmpty) {
      _showEmptyEmailDialog();
    } else {
      user = FirebaseAuth.instance.currentUser!.email.toString();
      String sourceEmail = user.replaceAll('.', '').replaceAll('@gmail.com', '');
      _showDeviceSelectionDialog(sourceEmail);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Text('Chia sẻ dữ liệu người dùng',style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.onPrimaryFixed,
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Center(child: Column(
                  children: [
                    SizedBox(height: 20,),
                    Text("Lưu ý",style: TextStyle(
                      color: Colors.red[800],
                      fontSize: 26,
                      fontWeight: FontWeight.bold
                    ),),
                    SizedBox(height: 10,),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                              text: "Xung đột dữ liệu: ",
                              style: TextStyle(
                                color: Colors.blue[300],
                                fontWeight: FontWeight.bold,
                              )
                          ),
                          TextSpan(
                              text: "Người dùng có thể bị xung đột dữ liệu nếu dữ liệu từ người dùng trước đó đã tồn tại."
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: 10,),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                              text: "Quyền truy cập: ",
                              style: TextStyle(
                                color: Colors.blue[300],
                                fontWeight: FontWeight.bold,
                              )
                          ),
                          TextSpan(
                              text: "Hiện tại chức năng phân quyền người dùng chưa được hỗ trợ (Người dùng khác sẽ có thể thêm, xóa, sửa dữ liệu của bạn). Bạn nên cân nhắc đến việc chia sẻ dữ liệu cho tài khoản khác."
                          )
                        ],
                      ),
                    ),
                  ],
                )),
                SizedBox(height: 10,),
                TextFormField(
                  controller: _destinationEmailController,
                  decoration: InputDecoration(
                    labelText: 'Email người dùng muốn chia sẻ',
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                    )
                  ),
                  cursorColor: Colors.green,
                ),
                SizedBox(height: 20,),
                ElevatedButton(
                  onPressed: _onConfirmPressed,
                  child: Text('Xác nhận',style: TextStyle(color: Colors.black),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.onPrimary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

