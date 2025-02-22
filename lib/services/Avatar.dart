import 'dart:io';
import 'package:demo2/authencation/Account_setting.dart';
import 'package:demo2/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class Avatar extends StatefulWidget {
  @override
  AvatarState createState() => AvatarState();
}

class AvatarState extends State<Avatar> {
  String user = "";
  String userAvatarUrl = '';
  File? image;
  bool _isLoading = false;

  @override
  Reference get storagee => FirebaseStorage.instance.ref();

  Future<String?> getImage() async {
    try {
      user = FirebaseAuth.instance.currentUser!.email.toString();
      String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');
      var urlRef = storagee.child("USER").child(modifiedUser).child("AVATAR").child("avatar.jpg");

      // Try to get the download URL from Firebase Storage
      var imgUrl = await urlRef.getDownloadURL();
      print(imgUrl);
      userAvatarUrl = imgUrl;
      return imgUrl;
    } catch (e) {
      print("Lỗi khi lấy ảnh từ Firebase Storage: $e");
      // Return the local placeholder path if Firebase fetch fails
      return 'assets/images/avatart_holder.png';
    }
  }

  Future pickImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final imageTemporary = File(image.path);

      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      setState(() {
        this.image = imageTemporary;
        // Simulate file upload and delay
        uploadFile().then((_) {
          Future.delayed(Duration(seconds: 3), () {
            // Hide loading indicator and navigate back to homepage after delay
            setState(() {
              _isLoading = false;
            });
            Navigator.push(context, MaterialPageRoute(builder: (context) => MyHomePage(title: ""))); // Navigate back to the homepage
          });
        });
      });
    } on PlatformException catch (e) {
      print("Error picking image: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future deleteLocalAvatarImage() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/avatar.jpg';  // Đường dẫn đến ảnh cũ
    final file = File(filePath);

    if (await file.exists()) {
      await file.delete();  // Xóa file nếu nó tồn tại
      print('Đã xóa ảnh cũ trong bộ nhớ cục bộ');
    }
  }

  Future uploadFile() async {
    if (image == null) return;

    // Xóa ảnh cũ trong bộ nhớ cục bộ trước khi upload ảnh mới
    await deleteLocalAvatarImage();

    // Get the current user's email
    user = FirebaseAuth.instance.currentUser!.email.toString();
    String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');

    // Define the storage path
    final destination = 'USER/$modifiedUser/AVATAR/avatar.jpg';

    try {
      // Reference to the storage path
      final ref = FirebaseStorage.instance.ref(destination);

      // Upload the file to the storage path
      await ref.putFile(image!);
      print('Ảnh đã được tải lên Firebase Storage');
    } catch (e) {
      print('Lỗi khi tải ảnh lên Firebase Storage: $e');
    }
  }


  @override
  void initState() {
    super.initState();
    getImage();
  }

  @override
  Widget build(BuildContext context) {
    user = FirebaseAuth.instance.currentUser!.email.toString();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Thay đổi ảnh đại diện',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
        color: Theme.of(context).colorScheme.onPrimaryFixed,
        child: ListView(
          children: [
            SizedBox(height: 160),
          FutureBuilder<String?>(
            future: getImage(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircleAvatar(
                  radius: 67,
                  backgroundColor: Colors.grey[200],
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == 'assets/images/avatar_holder.png') {
                return CircleAvatar(
                  radius: 67,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: AssetImage('assets/images/avatar_holder.png'),
                );
              } else {
                return CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.black,
                  child: CircleAvatar(
                    radius: 67,
                    backgroundImage: NetworkImage(snapshot.data!),
                  ),
                );
              }
            },
          ),
            SizedBox(height: 40),
            TextButton(
              onPressed: () async {
                pickImage();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 18),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onPrimary,
                  border: Border.all(color: Colors.grey, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Thêm hình ảnh từ thư viện",
                  style: TextStyle(color: Colors.black, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
