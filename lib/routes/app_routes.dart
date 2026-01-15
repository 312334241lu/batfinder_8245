import 'package:flutter/material.dart';

import '../presentation/ai_insights_screen/ai_insights_screen.dart';
import '../presentation/alert_dashboard/alert_dashboard.dart';
import '../presentation/alert_details/alert_details.dart';
import '../presentation/community_safety_chat/community_safety_chat.dart';
import '../presentation/emergency_panic_mode/emergency_panic_mode.dart';
import '../presentation/incident_reporting/incident_reporting.dart';
import '../presentation/interactive_safety_map/interactive_safety_map.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/onboarding_flow/onboarding_flow.dart';
import '../presentation/realtime_dashboard/realtime_dashboard_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/user_profile_settings/user_profile_settings.dart';
import '../presentation/user_registration/user_registration.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String splash = '/splash-screen';
  static const String login = '/login-screen';
  static const String onboardingFlow = '/onboarding-flow';
  static const String communitySafetyChat = '/community-safety-chat';
  static const String alertDashboard = '/alert-dashboard';
  static const String incidentReporting = '/incident-reporting';
  static const String alertDetails = '/alert-details';
  static const String emergencyPanicMode = '/emergency-panic-mode';
  static const String userProfileSettings = '/user-profile-settings';
  static const String userRegistration = '/user-registration';
  static const String interactiveSafetyMap = '/interactive-safety-map';
  static const String realtimeDashboard = '/realtime-dashboard';
  static const String aiInsightsScreen = '/ai-insights-screen';

  static Map<String, WidgetBuilder> get routes => {
    initial: (context) => const SplashScreen(),
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    onboardingFlow: (context) => const OnboardingFlow(),
    communitySafetyChat: (context) => const CommunitySafetyChat(),
    alertDashboard: (context) => const AlertDashboard(),
    incidentReporting: (context) => const IncidentReporting(),
    alertDetails: (context) => const AlertDetails(),
    emergencyPanicMode: (context) => const EmergencyPanicMode(),
    userProfileSettings: (context) => const UserProfileSettings(),
    userRegistration: (context) => const UserRegistration(),
    interactiveSafetyMap: (context) => const InteractiveSafetyMap(),
    realtimeDashboard: (context) => const RealtimeDashboardScreen(),
    aiInsightsScreen: (context) => const AIInsightsScreen(),
    // TODO: Add your other routes here
  };
}
