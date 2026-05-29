import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'map_screen.dart';
import 'pin_detail_screen.dart';
import 'pin_editor_screen.dart';
import 'timeline_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MapScreen(),
    ),
    GoRoute(
      path: '/timeline',
      builder: (context, state) => const TimelineScreen(),
    ),
    GoRoute(
      path: '/pins/new',
      builder: (context, state) => const PinEditorScreen(),
    ),
    GoRoute(
      path: '/pins/:pinId',
      builder: (context, state) {
        final pinId = state.pathParameters['pinId'] ?? '';
        return PinDetailScreen(pinId: pinId);
      },
    ),
    GoRoute(
      path: '/p/:token',
      builder: (context, state) {
        final token = state.pathParameters['token'] ?? '';
        return PublicSharedPinScreen(token: token);
      },
    ),
  ],
);

class PublicSharedPinScreen extends StatelessWidget {
  const PublicSharedPinScreen({required this.token, super.key});

  final String token;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shared Memory')),
      body: Center(child: Text(token)),
    );
  }
}
