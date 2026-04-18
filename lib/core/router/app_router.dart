import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:max_food/features/auth/presentation/screens/landing_page.dart';
import 'package:max_food/features/auth/presentation/screens/login_screen.dart';
import 'package:max_food/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:max_food/features/home/presentation/screens/home_screen.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  );

  ref.onDispose(() => refreshNotifier.dispose());

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuthenticated = session != null;
      final currentPath = state.matchedLocation;

      final authRoutes = ['/', '/login', '/sign-up'];
      final isOnAuthRoute = authRoutes.contains(currentPath);

      if (!isAuthenticated && !isOnAuthRoute) return '/';
      if (isAuthenticated && isOnAuthRoute) return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LandingPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
});
