import 'package:demo2/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../themes/theme_provider.dart';

class Messages extends StatefulWidget {
  @override
  MessagesState createState() => MessagesState();
}

class MessagesState extends State<Messages> {
  List<Map<String, String>> messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    messages.add({
      'text': "Xin chào! Chúng tôi có thể giúp được gì cho bạn! Hãy cho chúng tôi được biết bạn cần gì!",
      'type': 'auto',
    });
  }

  void _sendMessage() {
    if (_textController.text.isNotEmpty) {
      setState(() {
        messages.add({'text': _textController.text, 'type': 'user'});
        _checkForAutoReply(_textController.text);
        _textController.clear();
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _checkForAutoReply(String message) {
    if (message.toLowerCase().contains('thêm phòng')){
      setState(() {
        messages.add({'text': 'Đầu tiên bạn vào trang chủ', 'type': 'auto'});
        messages.add({'text': 'Tiếp đến bạn ấn vào nút thêm phòng kế bên số phòng hiện có', 'type': 'auto'});
        messages.add({'text': 'Điền thông tin phòng và xác nhận', 'type': 'auto'});
      });
    }
    else if (message.toLowerCase().contains('chào')){
      setState(() {
        messages.add({'text': 'Xin chào, bạn cần hỗ trợ gì ạ!', 'type': 'auto'});
      });
    }
    else if (message.toLowerCase().contains('ngu') || message.toLowerCase().contains('lồn') || message.toLowerCase().contains('chó')){
      setState(() {
        messages.add({'text': 'Có những từ ngữ không đúng chuẩn mực xin bạn hãy bình tĩnh', 'type': 'auto'});
      });
    }
    else if (message.toLowerCase().contains('tài khoản') || message.toLowerCase().contains('thanh toán') || message.toLowerCase().contains('mật khẩu')) {
      setState(() {
        messages.add({
          'text': 'Hãy liên hệ đến chúng tôi qua email: ',
          'type': 'auto',
          'email': 'hoangduy.dn64@gmail.com',
          'phone': '0338957922',
        });
      });
    }
    else if (message.toLowerCase().contains('kết nối') || message.toLowerCase().contains('thêm thiết bị')){
      setState(() {
        messages.add({'text': 'Đầu tiên bạn hãy vào cài đặt wifi trong máy bạn', 'type': 'auto'});
        messages.add({'text': 'Hãy kết nối với wifi của thiết bị phát ra', 'type': 'auto'});
        messages.add({'text': 'Sau khi kết nối thành công hãy quay trở lại app và thêm thiết bị', 'type': 'auto'});
      });
    }
    else {
      setState(() {
        messages.add({'text': 'Tôi chưa hiểu rõ ý bạn là gì?', 'type': 'auto'});
      });
    }
    _scrollToBottom();
  }

  String encodeQueryParameters(Map<String, String> params) {
    return params.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    String user = FirebaseAuth.instance.currentUser!.email.toString();
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Trung tâm hỗ trợ',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        body: Stack(
          children: [
            Container(
              // color: Theme.of(context).colorScheme.onPrimaryFixed,
              color: Colors.white ,
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
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      bool isAutoReply = messages[index]['type'] == 'auto';
                      return Align(
                        alignment: isAutoReply ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          padding: EdgeInsets.all(10.0),
                          margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                          decoration: BoxDecoration(
                            color: isAutoReply
                                ? (isDarkMode ? Colors.grey.shade800 : Colors.white)  // Màu nền tin nhắn tự động
                                : (isDarkMode ? Colors.blue.shade600 : Color(0xFFd9ead3)), // Màu nền tin nhắn của người dùng
                            borderRadius: BorderRadius.circular(10.0),
                            border: isAutoReply ? Border.all(color: Colors.grey) : null,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            child: isAutoReply
                                ? RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: messages[index]['text'],
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.white : Colors.black, // Màu chữ tin nhắn tự động
                                    ),
                                  ),
                                  if (messages[index].containsKey('email')) ...[
                                    TextSpan(
                                      text: '\nEmail: ',
                                      style: TextStyle(
                                          color: isDarkMode ? Colors.white : Colors.black),
                                    ),
                                    TextSpan(
                                      text: messages[index]['email'],
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () async {
                                          final Uri emailLaunchUri = Uri(
                                            scheme: 'mailto',
                                            path: messages[index]['email'],
                                            query: encodeQueryParameters({'subject': 'Hỗ trợ tài khoản: ${user}'}),
                                          );
                                          await launch(emailLaunchUri.toString());
                                        },
                                    ),
                                  ],
                                  if (messages[index].containsKey('phone')) ...[
                                    TextSpan(
                                      text: '\nHay Zalo: ',
                                      style: TextStyle(
                                          color: isDarkMode ? Colors.white : Colors.black),
                                    ),
                                    TextSpan(
                                      text: messages[index]['phone'],
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () async {
                                          final Uri phoneLaunchUri = Uri(
                                            scheme: 'tel',
                                            path: messages[index]['phone'],
                                          );
                                          await launch(phoneLaunchUri.toString());
                                        },
                                    ),
                                    TextSpan(
                                      text: ' để nhận được hỗ trợ về tài khoản của bạn',
                                      style: TextStyle(
                                          color: isDarkMode ? Colors.white : Colors.black),
                                    ),
                                  ],
                                ],
                              ),
                            )
                                : Text(
                              messages[index]['text']!,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black, // Màu chữ cho tin nhắn người dùng
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: 'Nhập tin nhắn',
                            hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                          cursorColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      IconButton(
                        onPressed: _sendMessage,
                        icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: Messages(),
  ));
}
