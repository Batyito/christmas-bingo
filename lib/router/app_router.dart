import 'package:flutter/material.dart';

import '../screens/invite_screen.dart';
import '../screens/contribute_by_code_screen.dart';
import '../screens/collaborate_pack_screen.dart';

/// Thin custom router to centralize route parsing and keep deep links intact.
///
/// Web deep links supported today:
/// - /invite?c=<code>
/// - /contribute?code=<code> (or c=)
/// - /collab?packId=<id>
class AppRouter {
  static Route<dynamic>? tryGenerate(RouteSettings settings) {
    final uriString = settings.name ?? '/';
    final uri = Uri.parse(uriString);

    switch (uri.path) {
      case '/invite':
        final code = uri.queryParameters['c'] ?? '';
        return MaterialPageRoute(
          builder: (_) => InviteLandingScreen(inviteCode: code),
          settings: settings,
        );
      case '/contribute':
        final code =
            uri.queryParameters['code'] ?? uri.queryParameters['c'] ?? '';
        return MaterialPageRoute(
          builder: (_) => ContributeByCodeScreen(initialCode: code),
          settings: settings,
        );
      case '/collab':
        final packId = uri.queryParameters['packId'];
        return MaterialPageRoute(
          builder: (_) => CollaboratePackScreen(initialPackId: packId),
          settings: settings,
        );
      default:
        return null; // Let caller fall back to default route
    }
  }
}
