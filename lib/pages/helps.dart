import 'package:demo2/components/QRScannerPage.dart';
import 'package:demo2/components/image_viewer_page.dart';
import 'package:demo2/services/Messages.dart';
import 'package:demo2/services/policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class Helps extends StatefulWidget {
  @override
  State<Helps> createState() => HelpsState();
}

class HelpsState extends State<Helps> {
  List<Notification> _listN =List.empty(growable: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Row(
          children: [
            Icon(Icons.help_sharp),
            Container(
              margin: EdgeInsets.symmetric(vertical: 10,horizontal: 15),
              child: Text(
                'Trợ giúp',
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
      // backgroundColor: Colors.white,
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
          Column(
            children: <Widget>[
              SizedBox(height: 10,),
              ListTile(
                leading: Icon(Icons.menu_book_outlined),
                title: Text('Hướng dẫn căn bản',style: TextStyle(fontWeight: FontWeight.bold),),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImageViewerPage(
                        title: 'Hướng dẫn căn bản',
                        imagePaths: [
                          'assets/images/huongdan/1.jpg',
                          'assets/images/huongdan/2.jpg',
                          'assets/images/huongdan/3.jpg',
                          'assets/images/huongdan/4.jpg',
                          'assets/images/huongdan/5.jpg',
                          'assets/images/huongdan/6.jpg',
                        ],
                        captions: [
                          'Thêm phòng',
                          'Thêm thiết bị',
                          'Trạng thái kết nối không thành công',
                          'Trạng thái kết nối thành công',
                          'Đăng kí thiết bị',
                          'Chỉnh sửa tên thiết bị',
                        ],
                      )
                    )
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text('Về chúng tôi',style: TextStyle(fontWeight: FontWeight.bold),),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>WebViewPage()));
                  // Code để xử lý khi người dùng nhấp vào "Về chúng tôi"
                },
              ),
              ListTile(
                leading: Icon(Icons.support_agent),
                title: Text('Trung tâm trợ giúp',style: TextStyle(fontWeight: FontWeight.bold),),
                onTap: () {
                  // Code để xử lý khi người dùng nhấp vào "Trung tâm trợ giúp"
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>Messages()));
                },
              ),
            ],
          ),
        ]
      )
    );
  }
}


