import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ionicons/ionicons.dart';

class AccountSetting extends StatefulWidget {

  @override
  AccountSettingState createState() => AccountSettingState();
}

class AccountSettingState extends State<AccountSetting> {
  String user = "";
  final _newPasswordController = TextEditingController();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _newPasswordController.text = "";
  }

  Future _changePassword(String password, BuildContext context) async{
    try{
      final user = FirebaseAuth.instance.currentUser!; //Xác định địa chỉ email đăng ký
      user.updatePassword(password).then((_){ //Hàm thay mật khẩu của Firebase
        print("Successfully changed password");
      }).catchError((error){
        print("Password can't be changed" + error.toString());
      });
    }
    on FirebaseAuthException catch  (e) {  //Nếu có lỗi sẽ thông báo duới màn hình
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message.toString()),
      ));
    }
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          title: Text('Thay đổi mật khẩu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _newPasswordController,
                decoration: InputDecoration(labelText: 'Nhập mật khẩu mới'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Hủy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.onPrimaryFixed,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                foregroundColor: Colors.white,
              ),
              child: Text('Lưu'),
              onPressed: () {
                _changePassword(_newPasswordController.text, context);
                setState(() {
                  Navigator.pop(context);
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context){
    user = FirebaseAuth.instance.currentUser!.email.toString();
    return Scaffold(
      appBar: AppBar(
        title: Text('Thay đổi mật khẩu',style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600),),
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Stack(
        children: [
          Container(
              color: Colors.white
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Email\n\n',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        )
                      ),
                      TextSpan(
                        text: user,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.normal,
                        )
                      )
                    ]
                  ),
                ),
                SizedBox(height: 40),
                GestureDetector(
                  onTap: () {
                    _showEditDialog();
                  },
                  child: Row(
                    children: [
                      RichText(
                        text: TextSpan(
                            children: [
                              TextSpan(
                                  text: 'Mật khẩu\n\n',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  )
                              ),
                              TextSpan(
                                  text: 'Thay đổi mật khẩu',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                    fontWeight: FontWeight.normal,
                                  )
                              )
                            ]
                        ),
                      ),
                      Spacer(),
                      Icon(Ionicons.lock_closed),
                      SizedBox(width: 20,),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ]
      ),
    );
  }
}