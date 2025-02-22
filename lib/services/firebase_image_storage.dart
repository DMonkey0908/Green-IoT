import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class FirebaseImageStorage {
  /// Phương thức kiểm tra và lấy ảnh avatar từ Firebase Storage và lưu vào bộ nhớ cục bộ nếu chưa có
  Future<File> getOrDownloadAvatar() async {
    try {
      // Kiểm tra xem ảnh đã có trong bộ nhớ cục bộ chưa
      final localFile = await getLocalAvatarImage();
      if (localFile != null) {
        // Ảnh đã tồn tại trong bộ nhớ cục bộ, trả về ảnh đó
        return localFile;
      } else {
        // Nếu chưa có ảnh, tải ảnh từ Firebase Storage và lưu
        return await downloadAndSaveAvatar();
      }
    } catch (e) {
      print('Lỗi khi lấy hoặc tải ảnh: $e');
      return await getPlaceholderImage(); // Trả về ảnh dự phòng nếu xảy ra lỗi
    }
  }

  /// Tải ảnh từ Firebase Storage và lưu vào bộ nhớ cục bộ nếu có, nếu không thì lấy ảnh dự phòng
  Future<File> downloadAndSaveAvatar() async {
    try {
      String user = FirebaseAuth.instance.currentUser!.email.toString();
      String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');
      final destination = 'USER/$modifiedUser/AVATAR/avatar.jpg';

      // Lấy tham chiếu ảnh từ Firebase Storage
      final storageRef = FirebaseStorage.instance.ref(destination);

      try {
        // Kiểm tra xem ảnh có tồn tại trên Firebase Storage không
        await storageRef.getDownloadURL();

        // Nếu tồn tại, tải ảnh về dưới dạng byte data
        final bytes = await storageRef.getData();
        if (bytes != null) {
          final directory = await getApplicationDocumentsDirectory();
          final filePath = '${directory.path}/avatar.jpg';

          // Lưu ảnh vào file
          final file = File(filePath);
          await file.writeAsBytes(bytes);

          return file;
        }
      } catch (e) {
        // Nếu ảnh không tồn tại, trả về ảnh dự phòng
        print('Ảnh không tồn tại trên Firebase Storage, sử dụng ảnh dự phòng.');
        return await getPlaceholderImage();
      }
    } catch (e) {
      print('Lỗi khi tải và lưu ảnh: $e');
    }
    // Trả về ảnh dự phòng nếu xảy ra lỗi trong quá trình tải
    return await getPlaceholderImage();
  }

  /// Lấy ảnh từ bộ nhớ cục bộ nếu đã tải trước đó
  Future<File?> getLocalAvatarImage() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/avatar.jpg';
    final file = File(filePath);

    if (await file.exists()) {
      return file;
    }
    return null;
  }

  /// Lấy ảnh dự phòng từ assets/images/avatar_holder.png
  Future<File> getPlaceholderImage() async {
    final byteData = await rootBundle.load('assets/images/avatart_holder.png');
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/avatar_holder.png';
    final file = File(filePath);

    // Lưu ảnh dự phòng vào file trong bộ nhớ cục bộ
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file;
  }
}
