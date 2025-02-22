import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo2/main.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'SignUp.dart';
import 'package:ionicons/ionicons.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Forgot_pass.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginState();
}

class _LoginState extends State<LoginPage> {
  String? _user = "";
  String? _pass = "";
  bool _showpass = true;

  Future Login (String email,String password,BuildContext context) async {
    try { await FirebaseAuth.instance.signInWithEmailAndPassword( //Hàm đanăng nhập của Firebase
        email: email,
        password: password);
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center (child:CircularProgressIndicator(color: Theme.of(context).colorScheme.primaryFixed,))); //Load 2s trước khi đăng nhập
    await Future.delayed(Duration(seconds: 2));
    Navigator.push(context, MaterialPageRoute(builder: (context)=>MyHomePage(title: "")));
    }on FirebaseAuthException catch  (e) { //Nếu có lỗi thì sẽ thông báo lỗi dưới màn hình
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message.toString()),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( //Widget khung
      body: SingleChildScrollView(
        child: Container(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 100,),
                Image(image: AssetImage("assets/images/main_logo.png"),height: 150,),
                // SizedBox(height: 10),
                Text(
                  'Chào mừng',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Đăng nhập để sử dụng dịch vụ IoT của chúng tôi.',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height:30),
                Container(
                  width: 320,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Color(0xAFd0d2d6),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child:
                  Padding(
                    padding:  EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(width: 10,),
                        Icon(Ionicons.person,color: Theme.of(context).colorScheme.onSurface,),
                        Container(
                          width:240,
                          child: Padding(
                            padding:  EdgeInsets.fromLTRB(0, 20, 0, 0),
                            child: TextFormField(
                              onChanged: (value) => _user = value,
                              cursorColor: Colors.grey,
                              style: TextStyle(color: Colors.black.withOpacity(0.7),fontSize: 11,fontWeight: FontWeight.bold),
                              controller: new TextEditingController.fromValue(new TextEditingValue(text: _user.toString(),selection: new TextSelection.collapsed(offset: _user.toString().length))),
                              decoration:  InputDecoration(
                                  enabledBorder: OutlineInputBorder(
                                    // width: 0.0 produces a thin "hairline" border
                                    borderSide:  BorderSide(color: Color(0x00474234),),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0x00474234),),
                                  ),
                                  hintText: "Nhập tài khoản",
                                  hintStyle: TextStyle(color: Color(0xAF5b5b5b),)
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 40,)
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  width: 320,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Color(0xAFd0d2d6),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(10)
                    ),
                  ),
                  child:
                  Padding(
                    padding:  EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(width: 10,),
                        Icon(Ionicons.lock_closed,color: Theme.of(context).colorScheme.onSurface,),
                        Container(
                          width:240,
                          child: Padding(
                            padding:  EdgeInsets.fromLTRB(0, 20, 0, 0),
                            child: TextFormField(
                              cursorColor: Colors.black.withOpacity(0.7),
                              onChanged: (value) => _pass = value,
                              style: TextStyle(color: Colors.black.withOpacity(0.7),fontSize: 16,fontWeight: FontWeight.bold),
                              controller: new TextEditingController.fromValue(new TextEditingValue(text: _pass.toString(),selection: new TextSelection.collapsed(offset: _pass.toString().length))),
                              decoration:  InputDecoration(
                                  enabledBorder:  OutlineInputBorder(
                                    // width: 0.0 produces a thin "hairline" border
                                    borderSide:  BorderSide(color: Color(0x00474234),),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0x00474234),),
                                  ),

                                  hintText: "Nhập mật khẩu",
                                  hintStyle: TextStyle(color: Color(0xAF5b5b5b),) //0x80E91E63
                              ),
                              obscureText:_showpass,
                            ),
                          ),
                        ),
                        Container(
                          width: 40,
                          padding:  EdgeInsets.fromLTRB(0, 3, 0, 0),
                          child: IconButton(
                            onPressed: (){
                              setState(() {
                                _showpass = !_showpass;
                              });
                            },
                            color: Colors.black.withOpacity(0.7),
                            icon: Icon(!_showpass?Icons.remove_red_eye:Icons.remove_red_eye_outlined,size: 20),),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10,),
                Row(
                  children: [
                    SizedBox(width: 200,),
                    TextButton(
                      onPressed: () {
                        // Handle Forgot Password
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ForgotPass(),));
                      },
                      child: Text('Quên mật khẩu?',style: TextStyle(fontSize: 16,color: Color(0xff93c47d)),),
                    ),
                  ],
                ),
                SizedBox(height: 10,),
                Container(
                  width: 320,
                  height: 40,
                  decoration: BoxDecoration(
                    // ... your existing decoration properties
                  ),
                  child: Center( // Wrap the ElevatedButton with Center
                    child: ElevatedButton(
                      onPressed: () async {
                        await Login(_user.toString(), _pass.toString(), context);
                        // Navigator.push(context, MaterialPageRoute(builder: (context) => Layout(),));
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(340, 50),
                        backgroundColor: Color(0xff93c47d),
                        foregroundColor: Color.fromRGBO(255, 255, 255, 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)
                        ),
                      ),
                      child: Text("Đăng Nhập"),
                    ),
                  ),
                ),

                SizedBox(height: 15,),
                Container(
                  width: 320,
                  height: 40,
                  decoration: BoxDecoration(
                    // ... your existing decoration properties
                  ),
                  child: Center( // Wrap the ElevatedButton with Center
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpScreen(),));
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(340, 50),
                        backgroundColor: Color(0xffD4D0CD),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)
                        ),
                      ),
                      child: Text("Tạo tài khoản"),
                    ),
                  ),
                ),

                // Đăng nhập với
                SizedBox(height: 34,),
                Text(
                  "Hoặc đăng nhập với",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () async {
                        // Đăng nhập bằng Google
                        final GoogleSignIn googleSignIn = GoogleSignIn();
                        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

                        if (googleUser != null) {
                          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

                          // Tạo thông tin đăng nhập Firebase
                          final AuthCredential credential = GoogleAuthProvider.credential(
                            accessToken: googleAuth.accessToken,
                            idToken: googleAuth.idToken,
                          );

                          try {
                            // Đăng nhập Firebase
                            UserCredential userCredential =
                            await FirebaseAuth.instance.signInWithCredential(credential);

                            // Nếu đăng nhập thành công, thực hiện các hành động tiếp theo
                            print('Đăng nhập thành công');
                            final String userEmail = userCredential.user!.email!;
                            final String modifiedUser = userEmail.replaceAll('.', '').replaceAll('@gmail.com', '');

                            // Cập nhật Firebase Realtime Database
                            final DatabaseReference df = FirebaseDatabase.instance.ref();
                            df.child(modifiedUser).set("");

                            // Cập nhật Firestore
                            await FirebaseFirestore.instance.collection('USERS').doc(modifiedUser).set({
                              'EMAIL': userEmail,
                            });

                            // Điều hướng đến trang chủ hoặc trang đầu tiên trong ngăn xếp
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          } on FirebaseAuthException catch (e) {
                            // Xử lý lỗi đăng nhập
                            print('Đăng nhập thất bại: ${e.message}');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Đăng nhập thất bại: ${e.message}')),
                            );
                          }
                        } else {
                          print('Đăng nhập bị hủy');
                        }
                      },
                      icon: Brand(Brands.google, size: 30),
                    ),
                    SizedBox(width: 10),
                  ],
                ),
                BottomAppBar(
                  color: Colors.white,
                  child: Text(
                    "Powered by Nguyễn Hoàng Duy",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      fontFamily: 'serif',
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
  bool _rememberMe = true;
}