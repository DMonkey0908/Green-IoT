import 'package:demo2/services/policy.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:ionicons/ionicons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Confirm.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool rememberMe = false;
  String? _user = "";
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();
  String? _pass = "";
  String? _confirmPass = "";
  bool _showpass = true;
  bool _passwordsMatch = false;

  Future SignUp(String email, String password, BuildContext context) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword( //Hàm đăng ký của Firebase
          email: email,
          password: password);
      Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpPassword())); //Chuyển qua trang xác nhận
    } on FirebaseAuthException catch (e) { //Nếu có lỗi sẽ thông báo duới màn hình
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message.toString()),
      ));
    }
  }

  void _checkPasswords() {
    setState(() {
      _passwordsMatch = _pass == _confirmPass;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
      ),
      body: Container(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  Text(
                    'Đăng kí,',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Nhập Email và Mật khẩu của bạn để đăng kí sử dụng dịch vụ',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  SizedBox(height: 15),
                  Container(
                    width: 410,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Color(0xAFd0d2d6),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(width: 10,),
                          Icon(Ionicons.person,color: Theme.of(context).colorScheme.onSurface,),
                          Container(
                            width: 240,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: TextFormField(
                                onChanged: (value) => setState(() => _user = value),
                                cursorColor: Colors.black.withOpacity(0.7),
                                style: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold),
                                controller: TextEditingController.fromValue(TextEditingValue(text: _user.toString(), selection: TextSelection.collapsed(offset: _user.toString().length))),
                                decoration: InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Color(0x00474234),),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Color(0x00474234),),
                                    ),
                                    hintText: "Nhập tài khoản email",
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
                  SizedBox(height: 15),
                  Container(
                    width: 410,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Color(0xAFd0d2d6),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(width: 10,),
                          Icon(Ionicons.lock_closed, color: Colors.black,),
                          Container(
                            width: 240,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: TextFormField(
                                cursorColor: Colors.black.withOpacity(0.7),
                                onChanged: (value) {
                                  setState(() {
                                    _pass = value;
                                    _checkPasswords();
                                  });
                                },
                                style: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 16, fontWeight: FontWeight.bold),
                                controller: TextEditingController.fromValue(TextEditingValue(text: _pass.toString(), selection: TextSelection.collapsed(offset: _pass.toString().length))),
                                decoration: InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Color(0x00474234),),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Color(0x00474234),),
                                    ),
                                    hintText: "Nhập mật khẩu",
                                    hintStyle: TextStyle(color: Color(0xAF5b5b5b),)
                                ),
                                obscureText: _showpass,
                              ),
                            ),
                          ),
                          Container(
                            width: 40,
                            padding: EdgeInsets.fromLTRB(0, 3, 0, 0),
                            child: IconButton(
                              onPressed: () {
                                setState(() {
                                  _showpass = !_showpass;
                                });
                              },
                              color: Colors.black.withOpacity(0.7),
                              icon: Icon(!_showpass ? Icons.remove_red_eye : Icons.remove_red_eye_outlined, size: 20),),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  Container(
                    width: 410,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Color(0xAFd0d2d6),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(width: 10,),
                          Icon(Ionicons.lock_closed, color: Colors.black,),
                          Container(
                            width: 240,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: TextFormField(
                                cursorColor: Colors.black.withOpacity(0.7),
                                onChanged: (value) {
                                  setState(() {
                                    _confirmPass = value;
                                    _checkPasswords();
                                  });
                                },
                                style: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 16, fontWeight: FontWeight.bold),
                                controller: TextEditingController.fromValue(TextEditingValue(text: _confirmPass.toString(), selection: TextSelection.collapsed(offset: _confirmPass.toString().length))),
                                decoration: InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Color(0x00474234),),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Color(0x00474234),),
                                    ),
                                    hintText: "Nhập lại mật khẩu",
                                    hintStyle: TextStyle(color: Color(0xAF5b5b5b),)
                                ),
                                obscureText: _showpass,
                              ),
                            ),
                          ),
                          SizedBox(width: 10,),
                          _passwordsMatch
                              ? Icon(Icons.check_circle, color: Colors.green, size: 20)
                              : Icon(Icons.error, color: Colors.red, size: 20),
                          SizedBox(width: 10,),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _passwordsMatch
                        ? () async {
                      // Handle Sign In
                      await SignUp(_user.toString(), _pass.toString(), context);
                    }
                        : null,
                    child: const Text(
                      'Tiếp theo', style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff93c47d),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 20,),
                  Container(
                    width: 360,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Bằng cách nhấp vào đăng kí, bạn đồng ý với ',
                            style: TextStyle(color: Colors.black),
                          ),
                          TextSpan(
                            text: 'Điều khoản dịch vụ',
                            style: TextStyle(color: Color(0xff93c47d), fontWeight: FontWeight.bold), // Highlight
                            recognizer: TapGestureRecognizer()
                              ..onTap = (){
                              Navigator.push(context, MaterialPageRoute(builder: (context)=>WebViewPage()));
                              }
                          ),
                          TextSpan(
                            text: ' và ',
                            style: TextStyle(color: Colors.black),
                          ),
                          TextSpan(
                            text: 'Chính sách quyền riêng tư',
                            style: TextStyle(color: Color(0xff93c47d), fontWeight: FontWeight.bold), // Highlight
                              recognizer: TapGestureRecognizer()
                                ..onTap = (){
                                  Navigator.push(context, MaterialPageRoute(builder: (context)=>WebViewPage()));
                                }
                          ),
                          TextSpan(
                            text: ' của chúng tôi.',
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Hoặc đăng nhập với'),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Brand(
                          Brands.google
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Hiện tại chức năng này đang được cập nhật'),
                            ),
                          );
                          // Handle Google Sign In
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
