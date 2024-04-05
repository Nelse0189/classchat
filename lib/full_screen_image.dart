import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'auth/constants.dart';

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: theme,
        titleTextStyle: TextStyle(fontFamily: 'sfPro', color: Colors.white, fontSize: 20),
        title: Text('Skubble', style: TextStyle(fontFamily: 'SfPro'),),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true, // Set it to false to prevent panning.
          boundaryMargin: EdgeInsets.all(80), // Adjust the space around the image if needed.
          minScale: 0.5, // Adjust the minimum scale level.
          maxScale: 4.0, // Adjust the maximum scale level.
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            placeholder: (context, url) => CircularProgressIndicator(),
            errorWidget: (context, url, error) => Icon(Icons.error),
            fit: BoxFit.contain, // This depends on your layout needs
          ),
        ),
      ),
      backgroundColor: theme2,
    );
  }
}

