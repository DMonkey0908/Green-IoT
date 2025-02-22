import 'package:demo2/pages/settings.dart';
import 'package:demo2/services/share_db.dart';
import 'package:demo2/components/showDevicesUser.dart';
import 'package:demo2/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:ionicons/ionicons.dart';
import 'dart:convert';
import 'dart:async';

class UsersList extends StatefulWidget {
  @override
  UsersListState createState() => UsersListState();
}

class UsersListState extends State<UsersList> {
  List<Users> _listu = List.empty(growable: true);
  int id = 0;
  String count = "";
  String email = "";
  String _searchText = "";

  String user1 = "";
  late DatabaseReference df;

  @override
  void initState() {
    super.initState();
    user1 = FirebaseAuth.instance.currentUser!.email.toString();
    String modifiedUser = user1.replaceAll('.', '').replaceAll('@gmail.com', '');
    df = FirebaseDatabase.instance.ref(); //Ðây là thu vi?n cu, thu vi?n m?i ta dùng ref()
    df.child("${modifiedUser}").child("USERS").onValue.listen((event) {
      List<Users> temp = List.empty(growable: true);
      print("Snapshot value: ${event.snapshot.value.toString()}");

      for(final child in event.snapshot.children) //T?o vòng l?p t?ng d?i tuo?ng trong list json d?c du?c ra
          {
        var encodedString = jsonEncode(child.value);  //Mã hóa d? th?c hi?n chuy?n d?i

        Map<String, dynamic> valueMap = json.decode(encodedString);  //Gi?i mã chu?i json

        Users user = Users.fromJson(valueMap); //Chuy?n d?i sang d?i tu?ng Device
        // print(user.id);
        setState(() {
          temp.add(user); //Add t?ng d?i tu?ng vào list t?m
          _listu.add(user);
        });
        // print(user.history[0].date);
      }

      setState(() {
        _listu = temp;
      });
    });
  }

  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.onPrimary,
          title: Text('Quản lý người dùng',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>MyHomePage(title: "")));
            },
          ),
        ),
        // backgroundColor: Colors.white,
        body: Container(
          color: Theme.of(context).colorScheme.onPrimaryFixed,
          child: Column(
            children: [
              Flexible(
                flex: 2,
                child: SizedBox(
                  height: 725,
                  width: 600,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 120,
                        left: (MediaQuery.of(context).size.width - 460) / 2,
                        bottom: 0.5,
                        child: SizedBox(
                          // margin: EdgeInsets.only(top: 180),
                          width: 460,
                          child: _buldListDevice(_listu),
                        ),
                      ),
                      Container(
                        width: 400,
                        height: 70,
                        child: Container(
                          width: 300,
                          height: 40,
                          child: TextField(
                            controller: _textController,
                            onChanged: (value) => setState(() => _searchText = value),
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm người dùng',
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.tertiaryContainer,
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
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 45),
                        height: 50,
                        color: Colors.grey[200],
                        child: Row(
                          children: [
                            SizedBox(width: 30.0),
                            Text(
                              "Số lượng người dùng: ${_listu.length}",
                              style: TextStyle(
                                fontSize: 14.0,
                              ),
                            ),
                            SizedBox(width: 55),
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
                                label: Text('Thêm',style: TextStyle(color: Colors.black,fontSize: 12),),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context)=>ShareDb()));
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
      ),
    );
  }
  Container _buildRoomContainer(Users user){
    return Container(
      child: Container(
        height: 100,
        margin: EdgeInsets.symmetric(vertical: 5,horizontal: 70),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey,
                blurRadius: 10,
                offset: Offset(0,5),
              ),
            ],
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
                  Color(0xFFffffff)
                ]
            )
        ),
        child: Row(
          children: [
            SizedBox(width: 10,),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10,),
                Row(
                  children: [
                    Text(
                      '${user.name.isEmpty ? 'Người dùng chưa xác định':user.name}',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: (){
                        _showEditDialog(user);
                      },
                      icon: Icon(
                        Icons.edit,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5,),
                Text(
                  '${user.email}',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            Spacer(flex: 1,),
            Column(
              children: [
                SizedBox(height: 25),
                Row(
                  children: [
                    IconButton(
                      onPressed: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DevicesPage(
                              accountName: (user.email != null && user.email.isNotEmpty) ? user.email : "Người dùng chưa xác định",  // Truyền vào tên tài khoản
                            ),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.list_alt,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    IconButton(
                      onPressed: (){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                              title: Text("Xóa quyền truy cập",style: TextStyle(fontWeight: FontWeight.bold),),
                              content: Text("Bạn có chắc chắn muốn xóa quyền truy cập của người dùng này không?"),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text("Không"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Lấy email và thực hiện các thao tác xóa
                                    String user1 = FirebaseAuth.instance.currentUser!.email.toString();
                                    String modifiedUser = user1.replaceAll('.', '').replaceAll('@gmail.com', '');
                                    String modifiedUser3 = user.email.replaceAll('.', '').replaceAll('@gmail.com', '');

                                    // Xóa quyền truy cập và dữ liệu của người dùng
                                    df.child(modifiedUser).child("USERS").child(modifiedUser3).remove();
                                    df.child(modifiedUser3).child("DEVICES").set("");
                                    df.child("HOME").child(modifiedUser3).remove();

                                    // Cập nhật lại danh sách người dùng
                                    setState(() {
                                      _listu.remove(user);
                                    });

                                    Navigator.of(context).pop(); // Đóng dialog sau khi xóa
                                  },
                                  child: Text("Có", style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            );
                          }
                        );
                      },
                      icon: Icon(
                        Ionicons.trash,
                        color: Colors.red[300],
                        size: 20,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10,),
              ],
            ),
            SizedBox(width: 10,)
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(Users user) async {
    String? roomName = user.name;
    user1 = FirebaseAuth.instance.currentUser!.email.toString();
    String modifiedUser = user1.replaceAll('.', '').replaceAll('@gmail.com', '');

    TextEditingController _controller = TextEditingController(text: user.name);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          title: Text(
            'Chỉnh sửa người dùng',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    cursorColor: Colors.green,
                    onChanged: (value) {
                      setState(() {
                        roomName = value;
                      });
                    },
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Đặt tên người dùng',
                      labelStyle: TextStyle(color: Colors.black),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.green,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.green,
                        ),
                      ),
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
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () {
                setState(() {
                  user.name = roomName!;
                });
                String modifiedUser3 = user.email.replaceAll('.', '').replaceAll('@gmail.com', '');
                df.child("${modifiedUser}").child("USERS").child("$modifiedUser3").update({
                  'NAME': roomName,
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  ListView _buldListDevice(List<Users> users) {//ListView t? danh sách Device
    List<Container> containers = users  //T?o list các container
        .where((user)=> user.email.toLowerCase().contains(_searchText.toLowerCase()))
        .map((user)=> _buildRoomContainer(user))
        .toList();
    return ListView(  //Tr? l?i giá tr? ListView
      children: [
        ...containers, //Ð?t list các container vào
      ],
    );
  }
}


class Users{
  late String email;
  late String name;

  Users({required this.email, required this.name,});

  factory Users.fromJson(Map<String, dynamic> json) {  //Hàm chuy?n t? json sang d?i tu?ng History
    return Users(
      email: json['EMAIL'],
      name: json['NAME'],
    );
  }

  Map toJson() => {  //Hàm chuy?n t? d?i tu?ng History sang d?ng json
    'EMAIL': email,
    'NAME': name,
  };

  @override
  String toString() {
    return '{${this.email},${this.name}';
  }
}
