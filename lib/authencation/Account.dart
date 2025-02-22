import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo2/authencation/Account_setting.dart';
import 'package:demo2/services/Avatar.dart';
import 'package:demo2/components/admin_account.dart';
import 'package:demo2/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ionicons/ionicons.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Account extends StatefulWidget {
  @override
  AccountState createState() => AccountState();
}

class AccountState extends State<Account> {
  String user = "";
  String userAvatarUrl = '';

  @override
  Reference get storagee => FirebaseStorage.instance.ref();
  bool isUserExists = false;
  bool isUserExists2 = false;

  void checkUserInFirebase() async {
    String user = FirebaseAuth.instance.currentUser!.email.toString();
    String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');

    // Reference to the Firestore collection
    CollectionReference adminUsers = FirebaseFirestore.instance.collection('ADMIN_USERS');

    // Check if the user exists in the "ADMIN_USERS" collection
    final snapshot = await adminUsers.doc(modifiedUser).get();

    // Check if the document exists and if the EMAIL field matches the current user's email
    if (snapshot.exists) {
      // Cast the data to Map<String, dynamic>
      Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

      // Check if the EMAIL field is not null and matches the current user's email
      String? emailField = data?['EMAIL'];
      setState(() {
        isUserExists = (emailField == user);
      });
    } else {
      setState(() {
        isUserExists = false; // User does not exist
      });
    }
  }

  void checkUserInFirestore() async {
    String user = FirebaseAuth.instance.currentUser!.email.toString();
    String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');

    // Reference to the Firestore collection
    CollectionReference adminUsers = FirebaseFirestore.instance.collection('FAMILY');

    // Check if the user exists in the "ADMIN_USERS" collection
    final snapshot = await adminUsers.doc(modifiedUser).get();

    // Check if the document exists and if the EMAIL field matches the current user's email
    if (snapshot.exists) {
      // Cast the data to Map<String, dynamic>
      Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

      // Check if the EMAIL field is not null and matches the current user's email
      String? emailField = data?['EMAIL'];
      setState(() {
        isUserExists2 = (emailField == user);
      });
    } else {
      setState(() {
        isUserExists2 = false; // User does not exist
      });
    }
  }

  Future<String?> getImage() async {
    try {
      user = FirebaseAuth.instance.currentUser!.email.toString();
      String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');
      var urlRef = storagee.child("USER").child(modifiedUser).child("AVATAR").child("avatar.jpg");
      var imgUrl = await urlRef.getDownloadURL();
      userAvatarUrl = imgUrl;
      return imgUrl;
    } catch (e) {
      print("Lỗi");
      return 'assets/images/avatart_holder.png';
    }
  }

  @override
  void initState() {
    super.initState();
    checkUserInFirebase();
    checkUserInFirestore();
  }

  @override
  Widget build(BuildContext context) {
    user = FirebaseAuth.instance.currentUser!.email.toString();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tài khoản',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
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
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context, MaterialPageRoute(builder: (context) => Avatar()));
                  },
                  child: Center(
                    child: Stack(
                      children: [
                        FutureBuilder<String?>(
                          future: getImage(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircleAvatar(
                                radius: 38,
                                backgroundColor: Colors.black,
                                child: CircleAvatar(
                                  radius: 37,
                                  backgroundColor: Colors.grey[200],
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            } else if (snapshot.hasError || !snapshot.hasData) {
                              return CircleAvatar(
                                backgroundColor: Colors.black,
                                radius: 38,
                                child: CircleAvatar(
                                  radius: 37,
                                  backgroundColor: Colors.grey[200],
                                  child: Icon(Icons.error, color: Colors.red),
                                ),
                              );
                            } else {
                              return CircleAvatar(
                                radius: 38,
                                backgroundColor: Colors.black,
                                child: CircleAvatar(
                                  radius: 37,
                                  backgroundImage: NetworkImage(snapshot.data!),
                                ),
                              );
                            }
                          },
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 11,
                            backgroundColor: Colors.black,
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.edit,
                                color: Colors.black,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                        isUserExists
                            ? Positioned(
                          right: 0,
                          top: 0,
                          child: CircleAvatar(
                            radius: 11,
                            backgroundColor: Colors.black12,
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.diamond,
                                color: Colors.yellow[800],
                                size: 16,
                              ),
                            ),
                          ),
                        )
                            : SizedBox.shrink(),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    '$user',
                    textAlign: TextAlign.start,
                    style: TextStyle(fontSize: 16, color: Colors.blue[400]),
                  ),
                ),
                SizedBox(height: 40),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AccountSetting()));
                  },
                  child: Row(
                    children: [
                      Icon(Ionicons.person_circle,color: Colors.blue[300],),
                      SizedBox(width: 5),
                      Text(
                        'Tài khoản và bảo mật',
                        style: TextStyle(fontSize: 16),
                      ),
                      Spacer(),
                      Icon(Ionicons.chevron_forward_circle_outline)
                    ],
                  ),
                ),
                SizedBox(height: 30),
                Visibility(
                  visible: !(isUserExists2),
                  child: GestureDetector(
                    onTap: () {
                      if (isUserExists) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                              title: Text('Bạn đã là nhà phát triển ứng dụng',style: TextStyle(fontSize: 16,),textAlign: TextAlign.center,),
                              // content: Text('Bạn đã là nhà phát triển ứng dụng'),
                              actions: [
                                Center(
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(); // Đóng dialog
                                    },
                                    child: Text('OK',style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold),textAlign: TextAlign.center,),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AdminAccount()),
                        );
                      }
                    },
                    child: Row(
                      children: [
                        Icon(Ionicons.diamond, color: Colors.yellow[800]),
                        SizedBox(width: 5),
                        Text(
                          'Nâng cấp tài khoản cho nhà phát triển',
                          style: TextStyle(fontSize: 14),
                        ),
                        Spacer(),
                        Icon(Ionicons.chevron_forward_circle_outline),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
