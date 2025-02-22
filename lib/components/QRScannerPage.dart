import 'package:demo2/components/result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRScannerPage extends StatefulWidget {
  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> with SingleTickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  late AnimationController animationController;
  bool scannSuccess = false;

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "QR Scanner",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Container(
        color: Theme.of(context).colorScheme.onPrimaryFixed,
        child: Column(
          children: [
            Spacer(flex: 1), // Khoảng cách phía trên
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60.0,vertical: 100),
                child: AspectRatio(
                  aspectRatio: 1, // Đảm bảo khung hình vuông
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // QRView bên trong
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: scannSuccess ? Colors.blue : Colors.green,
                            width: 4,
                          ),
                        ),
                        child: QRView(
                          key: qrKey,
                          onQRViewCreated: _onQRViewCreated,
                        ),
                      ),
                      AnimatedBuilder(
                        animation: animationController,
                        builder: (context, child) {
                          return Positioned(
                            top: animationController.value * (MediaQuery.of(context).size.width -120),
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 4,
                              color: scannSuccess ? Colors.blue : Colors.green,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Spacer(flex: 1), // Khoảng cách phía dưới
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  minimumSize: Size(double.infinity, 50), // Nút rộng toàn màn hình trong khoảng padding
                ),
                onPressed: () async {
                  await controller?.resumeCamera();
                },
                child: Text(
                  'Tiếp tục quét',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
            SizedBox(height: 16), // Khoảng cách dưới nút
          ],
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        scannSuccess = true;
      });
      controller.pauseCamera(); // Tạm dừng camera sau khi quét
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage(result: scanData.code ?? 'Không có dữ liệu'),
        ),
      ).then((_) {
        setState(() {
          scannSuccess = false;
        });
        controller.resumeCamera(); // Tiếp tục quét khi quay lại
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
