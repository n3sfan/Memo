import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PinDetailScreen extends StatelessWidget {
  const PinDetailScreen({required this.pinId, super.key});

  final String pinId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory'),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              context.push('/pins/${Uri.encodeComponent(pinId)}/edit');
            },
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit memory',
          ),
        ],
      ),
      body: Center(child: Text(pinId)),
    );
  }
}
