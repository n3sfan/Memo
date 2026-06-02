import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/models.dart';
import 'map_screen.dart';
import 'pin_detail_screen.dart';
import 'pin_editor_screen.dart';
import 'timeline_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => MapScreen(
        startPicking: state.uri.queryParameters['pick'] == '1',
        editPinId: state.uri.queryParameters['editPinId'],
      ),
    ),
    GoRoute(
      path: '/timeline',
      builder: (context, state) => const TimelineScreen(),
    ),
    GoRoute(
      path: '/pins/new',
      builder: (context, state) {
        return PinEditorScreen(
          initialCoordinates: _coordinatesFromQuery(state.uri),
        );
      },
    ),
    GoRoute(
      path: '/pins/:pinId/edit',
      builder: (context, state) {
        final pinId = state.pathParameters['pinId'] ?? '';
        return PinEditorScreen(
          pinId: pinId,
          initialCoordinates: _coordinatesFromQuery(state.uri),
        );
      },
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

Coordinates? _coordinatesFromQuery(Uri uri) {
  final double? lat = double.tryParse(uri.queryParameters['lat'] ?? '');
  final double? lng = double.tryParse(uri.queryParameters['lng'] ?? '');
  if (lat == null || lng == null) {
    return null;
  }

  return Coordinates(lat: lat, lng: lng);
}

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
