import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

enum NotificationType {
  accident_alert,
  system,
  general,
}

@freezed
abstract class UserNotification with _$UserNotification {
  const factory UserNotification({
    required String notificationId,
    required String title,
    required String body,
    required String type,
    required bool isRead,
    @Default({}) Map<String, dynamic> data,
    required DateTime createdAt,
  }) = _UserNotification;

  factory UserNotification.fromJson(Map<String, dynamic> json) => _$UserNotificationFromJson(json);
}