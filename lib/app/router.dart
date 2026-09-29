import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// TEMPLATE NOTE: the `/` route below is a placeholder so the app boots.
/// Delete it (and its `Scaffold` import usage) when adding real routes.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Template ready')),
      ),
    ),
  ],
);
