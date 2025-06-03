import 'dart:convert';

import 'package:flutter/material.dart';

class Base64ImageWidget extends StatelessWidget {
  final String base64String;

  const Base64ImageWidget({
    super.key,
    required this.base64String,
  });

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      const Base64Decoder().convert(base64String),
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey[400],
          size: 50,
        ),
      ),
    );
  }
}
