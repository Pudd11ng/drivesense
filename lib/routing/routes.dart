abstract final class Routes {
  static const home = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot_password';
  static const resetPassword = '/reset-password';
  static const settings = '/settings';
  static const profile = '/profile';
  static const profileCompletion = '/profile_completion';
  static const connectDevice = '/connect_device';
  static const device = '/device/:deviceId';
  static const manageAlert = '/manage_alert';
  static const extraConfig = '/extra_config/:alertTypeName';
  static const drivingHistory = '/driving_history';
  static const drivingAnalysis = '/driving_analysis/:drivingHistoryId';
  static const emergencyContact = '/emergency_contact';
  static const emergencyContactInvitation = '/emergency-invite';
  static const notification = '/notifications';
}
