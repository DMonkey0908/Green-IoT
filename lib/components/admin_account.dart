import 'package:demo2/services/Messages.dart';
import 'package:demo2/services/payment.dart';
import 'package:demo2/services/policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';
import '../authencation/Account.dart';


class AdminAccount extends StatefulWidget {
  @override
  State<AdminAccount> createState() => AdminAccountState();
}

class AdminAccountState extends State<AdminAccount> {
  List<Notification> _listN =List.empty(growable: true);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).colorScheme.onPrimary,
          title: Row(
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 10,horizontal: 15),
                child: Text(
                  'Tài khoản cho nhà phát triển',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        // backgroundColor: Colors.white,
        body: Container(
          color: Theme.of(context).colorScheme.onPrimaryFixed,
          child: Column(
            children: <Widget>[
              SizedBox(height: 20,),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.account_circle,color: Colors.yellow[600],size: 50,),
                    SizedBox(height: 10,),
                    Text("Nhà phát triển", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
                    SizedBox(height: 5,),
                    Text("Mở khóa các tính năng cho người dùng Admin")
                  ],
                ),
              ),
              SizedBox(height: 10,),
              ListTile(
                leading: Icon(Icons.add_moderator_rounded),
                title: Text('Bảo mật tuyệt đối'),
                onTap: () {
                  // Code để xử lý khi người dùng nhấp vào "Kết nối thiết bị"
                },
              ),
              ListTile(
                leading: Icon(Icons.admin_panel_settings),
                title: Text('Mở khóa tính năng cho nhà phát triển'),
                onTap: () {
                  // Code để xử lý khi người dùng nhấp vào "Vấn đề về tài khoản"
                },
              ),
              ListTile(
                leading: Icon(Icons.content_copy_rounded),
                title: Text('Chia sẽ dữ liệu cho người dùng khác'),
                onTap: () {
                  // Code để xử lý khi người dùng nhấp vào "Dữ liệu"
                },
              ),
              ListTile(
                leading: Icon(Icons.block),
                title: Text('Chặn người dùng khác truy cập vào thiết bị'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>WebViewPage()));
                  // Code để xử lý khi người dùng nhấp vào "Về chúng tôi"
                },
              ),
              ListTile(
                leading: Icon(Icons.group),
                title: Text('Quản lí người dùng đã đăng kí'),
                onTap: () {
                  // Code để xử lý khi người dùng nhấp vào "Trung tâm trợ giúp"
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>Messages()));
                },
              ),
              SizedBox(height: 20,),
              SizedBox(
                width: 280, // Chiều ngang của nút
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PaymentPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF93c47d), // Màu nền
                    padding: EdgeInsets.symmetric(vertical: 16), // padding của nút
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Căn giữa cả icon và text
                    children: [
                      Text(
                        'Nâng cấp tài khoản nhà phát triển',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.bold, // Màu và kiểu chữ
                        ),
                      ),
                      SizedBox(width: 10), // Khoảng cách giữa text và icon
                      Icon(Icons.lock_open_sharp,color: Colors.black,),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10,),
              SizedBox(
                width: 280, // Chiều ngang của nút
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Account()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: null, // Màu nền
                    padding: EdgeInsets.symmetric(vertical: 16), // padding của nút
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Căn giữa cả icon và text
                    children: [
                      Text(
                        'Quay lại',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
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
}


