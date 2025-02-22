import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentPage extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _selectedPaymentMethod = 'Momo'; // Phương thức thanh toán mặc định

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thanh toán',style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Container(
        color: Theme.of(context).colorScheme.onPrimaryFixed,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chọn hình thức thanh toán:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              // Lựa chọn thanh toán qua Momo
              RadioListTile<String>(
                activeColor: Colors.green,
                title: Text('Thanh toán qua Momo'),
                value: 'Momo',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
              ),

              // Lựa chọn thanh toán qua tài khoản ngân hàng
              RadioListTile<String>(
                activeColor: Colors.green,
                title: Text('Thanh toán qua tài khoản ngân hàng'),
                value: 'Bank',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
              ),

              Spacer(),

              // Nút xác nhận thanh toán
              Center(
                child: SizedBox(
                  width: 280,
                  child: ElevatedButton(
                    onPressed: () {
                      _confirmPayment(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer, // Màu nền
                      padding: EdgeInsets.symmetric(vertical: 16), // padding của nút
                    ),
                    child: Text('Xác nhận thanh toán',style: TextStyle(color: Colors.black),),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hàm xử lý khi người dùng nhấn "Xác nhận thanh toán"
  void _confirmPayment(BuildContext context) {
    String message;
    String imagePath;

    if (_selectedPaymentMethod == 'Momo') {
      message = 'Thanh toán qua Momo.';
      imagePath = 'assets/images/momo.jpg'; // Đường dẫn tới ảnh Momo (đặt trong thư mục assets)
    } else if (_selectedPaymentMethod == 'Bank') {
      message = 'Thanh toán qua tài khoản ngân hàng.';
      imagePath = 'assets/images/TPbank.jpg'; // Đường dẫn tới ảnh tài khoản ngân hàng
    } else {
      message = 'Vui lòng chọn hình thức thanh toán.';
      imagePath = ''; // Không có hình ảnh nếu chưa chọn phương thức
    }

    // Hiển thị dialog xác nhận
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          content: Column(
            mainAxisSize: MainAxisSize.min, // Đảm bảo dialog không bị giãn quá to
            children: [
              Text(message),
              SizedBox(height: 20), // Khoảng cách giữa text và hình ảnh
              if (imagePath.isNotEmpty) // Nếu có hình ảnh thì hiển thị
                Image.asset(
                  imagePath,
                  height: 300, // Chiều cao của hình ảnh
                  width: 250,
                ),
              SizedBox(height: 10,),
              Text("Sau khi thanh toán thành công hệ thống sẽ tự động kích hoạt nâng cấp cho tài khoản của bạn"),
              SizedBox(height: 5,),
              Text("Nếu gặp vấn đề về thanh toán, hãy liên hệ với đội ngũ hỗ trợ của chúng tôi ở phần 'Trợ giúp'.",style: TextStyle(fontSize: 12,color: Colors.red),)
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                String user = "";
                user = FirebaseAuth.instance.currentUser!.email.toString();
                String modifiedUser = user.replaceAll('.', '').replaceAll('@gmail.com', '');

                FirebaseFirestore.instance.collection('USERS').doc(modifiedUser).set({
                  'EMAIL': user,
                }).then((value) {
                  Navigator.of(context).pop(); // Đóng dialog khi ghi dữ liệu thành công
                }).catchError((error) {
                  print("Failed to add user: $error");
                });
                Navigator.of(context).pop(); // Đóng dialog
              },
              child: Text('OK',style: TextStyle(color: Colors.black),),
            ),
          ],
        );
      },
    );
  }
}
