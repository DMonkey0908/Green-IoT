import 'package:flutter/material.dart';

class ImageViewerPage extends StatelessWidget {
  final String title;
  final List<String> imagePaths;
  final List<String> captions;

  const ImageViewerPage({
    Key? key,
    required this.title,
    required this.imagePaths,
    required this.captions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Text(
          title,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: PageView.builder(
        itemCount: imagePaths.length,
        itemBuilder: (context, index) {
          return Column(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "Lướt sang phải để xem thêm",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.tertiaryFixed,
                      backgroundColor: Theme.of(context).colorScheme.background,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 8,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.asset(
                    imagePaths[index],
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    captions[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.tertiaryFixed,
                      backgroundColor: Theme.of(context).colorScheme.background,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
