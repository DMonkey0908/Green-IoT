import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPassword extends StatefulWidget {
  const SignUpPassword({Key? key}) : super(key: key);

  @override
  _SignUpPasswordScreenState createState() => _SignUpPasswordScreenState();
}

class _SignUpPasswordScreenState extends State<SignUpPassword> {
  bool rememberMe = false;
  bool isEmailVerified=false;
  Timer? timer;
  String user="";
  late DatabaseReference df;

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

  Future VerifyEmail (BuildContext context) async {
    try{
      final user = FirebaseAuth.instance.currentUser!; //Xác định địa chỉ email đăng ký
      await user.sendEmailVerification(); //Gưi email qua địa chỉ đó
    }
    on FirebaseAuthException catch  (e) {  //Nếu có lỗi sẽ thông báo duới màn hình
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message.toString()),
      ));
    }
  }

  Future checkVerifyEmail (BuildContext context,bool isEmailVerified,Timer? timer) async {
    await FirebaseAuth.instance.currentUser!.reload();
    isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified; //Kiểm tra hàm bool xác nhận email
    if (isEmailVerified){ //Nếu đã xác nhận thì tiến vào App
      timer?.cancel;
      _showLoadingDialog();
      user = FirebaseAuth.instance.currentUser!.email.toString();
      String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');
      df = FirebaseDatabase.instance.ref();
      df.child(modifiedUser).set("");
      await FirebaseFirestore.instance.collection('USERS').doc(modifiedUser).set({
        'EMAIL': user,
      });
      await Future.delayed(Duration(seconds: 3));
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  void initState(){
    super.initState();
    isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;

    if (!isEmailVerified){
      VerifyEmail(context);
    }

    timer = Timer.periodic(
      Duration(seconds: 3),
          (_)=>checkVerifyEmail(context,isEmailVerified,timer),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    'Xác nhận',
                    style: TextStyle(
                      color: Color(0xFF93c47d),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Thông báo đăng kí sẽ được gửi vào email của bạn hãy kiểm tra và click vào link để xác nhận sử dụng dịch vụ',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16,fontWeight: FontWeight.w400),
                  ),
                  SizedBox(height: 10,),
                  Text(
                    'Sau khi xác nhận hệ thống sẽ tự động đăng nhập',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14,fontWeight: FontWeight.w400,color: Colors.red[300]),
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