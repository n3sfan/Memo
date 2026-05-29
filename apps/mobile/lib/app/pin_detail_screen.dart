import 'package:flutter/material.dart';

class PinDetailScreen extends StatelessWidget {
  const PinDetailScreen({required this.pinId, super.key});

  final String pinId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memory')),
      body: Center(child: Text(pinId)),
    );
  }
}
