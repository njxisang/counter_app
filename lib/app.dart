import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'pages/home_page.dart';
import 'pages/project_detail_page.dart';
import 'pages/project_edit_page.dart';
import 'pages/stats_page.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/project/new',
      builder: (context, state) => const ProjectEditPage(),
    ),
    GoRoute(
      path: '/project/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return ProjectDetailPage(projectId: id);
      },
    ),
    GoRoute(
      path: '/project/:id/edit',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return ProjectEditPage(projectId: id);
      },
    ),
    GoRoute(
      path: '/project/:id/stats',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return StatsPage(projectId: id);
      },
    ),
  ],
);

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '计数统计',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
