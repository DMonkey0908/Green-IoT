import 'package:demo2/authencation/Login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPass extends StatefulWidget {
  @override
  _ForgotPassState createState() => _ForgotPassState();
}

class _ForgotPassState extends State<ForgotPass> {
  Future ForgetPass (String email,BuildContext context) async {
    try{
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email); //Gửi mật khẩu mới qua email
      Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage())); //Chuyển qua trang Login để đăng nhập
    }
    on FirebaseAuthException catch  (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message.toString()),
      ));
    }
  }
  String _user = "";
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
                children: [
                  Text(
                    'Quên mật khẩu,',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Nhập Email để cấp lại mật khẩu',
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
                                    hintText: "Nhập tài khoản",
                                    hintStyle: TextStyle(color: Color(0xAF5b5b5b),)
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20,),
                  Container(
                    width: 320,
                    height: 50,
                    decoration: BoxDecoration(
                      // ... your existing decoration properties
                    ),
                    child: Center( // Wrap the ElevatedButton with Center
                      child: ElevatedButton(
                        onPressed: () async {
                          await ForgetPass(_user, context);
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
                        child: Text("Xác nhận"),
                      ),
                    ),
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
