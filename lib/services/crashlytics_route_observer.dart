import 'package:flutter/widgets.dart';
import 'package:total_athlete/services/crashlytics_service.dart';

/// Route observer that logs screen changes to Crashlytics
class CrashlyticsRouteObserver extends RouteObserver<ModalRoute<dynamic>> {
  final CrashlyticsService _crashlytics = CrashlyticsService();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _logRoute(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _logRoute(newRoute);
    }
  }

  void _logRoute(Route<dynamic> route) {
    if (route.settings.name != null) {
      final screenName = route.settings.name!;
      _crashlytics.logScreen(screenName);
    }
  }
}
