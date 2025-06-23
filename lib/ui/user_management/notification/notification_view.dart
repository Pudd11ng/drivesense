import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:drivesense/domain/models/notification/notification.dart';
import 'package:drivesense/ui/user_management/view_model/user_management_view_model.dart';
import 'package:drivesense/ui/core/widgets/app_header_bar.dart';
import 'package:drivesense/ui/core/themes/colors.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    final viewModel = Provider.of<UserManagementViewModel>(
      context,
      listen: false,
    );
    await viewModel.fetchNotifications(refresh: true);
  }

  Future<void> _loadMoreNotifications() async {
    final viewModel = Provider.of<UserManagementViewModel>(
      context,
      listen: false,
    );
    if (!viewModel.isLoadingNotifications && viewModel.hasMoreNotifications) {
      await viewModel.fetchNotifications();
    }
  }

  Future<void> _markAllAsRead() async {
    final viewModel = Provider.of<UserManagementViewModel>(
      context,
      listen: false,
    );
    final success = await viewModel.markAllNotificationsAsRead();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear All Notifications'),
            content: const Text(
              'Are you sure you want to delete all notifications?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('CLEAR ALL'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final viewModel = Provider.of<UserManagementViewModel>(
        context,
        listen: false,
      );
      final success = await viewModel.clearAllNotifications();

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications cleared')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.black : AppColors.white;
    final textColor = isDarkMode ? AppColors.white : AppColors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppHeaderBar(
        title: 'Notifications',
        leading: Icon(Icons.arrow_back),
        onLeadingPressed: () => context.go('/'),
        actions: [
          Consumer<UserManagementViewModel>(
            builder: (context, viewModel, _) {
              if (viewModel.notifications.isNotEmpty) {
                return Row(
                  children: [
                    if (viewModel.unreadCount > 0)
                      IconButton(
                        icon: Icon(
                          Icons.done_all,
                          color:
                              isDarkMode ? AppColors.blue : AppColors.darkBlue,
                        ),
                        onPressed: _markAllAsRead,
                        tooltip: 'Mark all as read',
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_sweep,
                        color: isDarkMode ? AppColors.blue : AppColors.darkBlue,
                      ),
                      onPressed: () => _clearAll(),
                      tooltip: 'Clear all notifications',
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadNotifications(),
        child: Consumer<UserManagementViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoadingNotifications &&
                viewModel.notifications.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.notificationError != null &&
                viewModel.notifications.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color:
                            isDarkMode
                                ? AppColors.red.withValues(alpha: 0.8)
                                : AppColors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error Loading Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        viewModel.notificationError!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textColor),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadNotifications,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDarkMode ? AppColors.blue : AppColors.darkBlue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (viewModel.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount:
                  viewModel.notifications.length +
                  (viewModel.hasMoreNotifications ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == viewModel.notifications.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final notification = viewModel.notifications[index];
                return _buildNotificationItem(
                  context,
                  notification,
                  viewModel,
                  isDarkMode,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    UserNotification notification,
    UserManagementViewModel viewModel,
    bool isDarkMode,
  ) {
    return Dismissible(
      key: Key(notification.notificationId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        await viewModel.deleteNotification(notification.notificationId);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Notification deleted')));
        }
      },
      child: Card(
        elevation: notification.isRead ? 1 : 3,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        color:
            notification.isRead
                ? null
                : (isDarkMode
                    ? AppColors.blue.withValues(alpha: 0.1)
                    : AppColors.blue.withValues(alpha: 0.05)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side:
              notification.isRead
                  ? BorderSide.none
                  : BorderSide(
                    color:
                        isDarkMode
                            ? AppColors.blue.withValues(alpha: 0.5)
                            : AppColors.blue.withValues(alpha: 0.3),
                    width: 1,
                  ),
        ),
        child: InkWell(
          onTap: () => _handleNotificationTap(notification, viewModel),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _getNotificationIcon(notification.type),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight:
                              notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[300] : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(notification.createdAt),
                        style: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  IconButton(
                    icon: const Icon(Icons.mark_email_read, size: 20),
                    color: AppColors.blue,
                    onPressed:
                        () =>
                            _markAsRead(notification.notificationId, viewModel),
                    tooltip: 'Mark as read',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    switch (type) {
      case 'accident_alert':
        return CircleAvatar(
          radius: 20,
          backgroundColor: Colors.red.withValues(alpha: 0.2),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
            size: 24,
          ),
        );
      case 'system':
        return CircleAvatar(
          radius: 20,
          backgroundColor: Colors.blue.withValues(alpha: 0.2),
          child: const Icon(Icons.info, color: Colors.blue, size: 24),
        );
      default:
        return CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey.withValues(alpha: 0.2),
          child: const Icon(Icons.notifications, color: Colors.grey, size: 24),
        );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      // Format as MM/DD/YYYY
      return DateFormat('MM/dd/yyyy').format(date);
    } else if (difference.inDays > 0) {
      // Format as "X days ago"
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      // Format as "X hours ago"
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      // Format as "X minutes ago"
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      // Format as "Just now"
      return 'Just now';
    }
  }

  Future<void> _handleNotificationTap(
    UserNotification notification,
    UserManagementViewModel viewModel,
  ) async {
    try {
      debugPrint('Notification tapped: ${notification.notificationId}');
      // Mark as read when tapped
      if (!notification.isRead) {
        final success = await viewModel.markNotificationAsRead(
          notification.notificationId,
        );
        debugPrint('Notification marked as read: $success');

        // Refresh the notification list to reflect changes
        if (!mounted) return;
      }

      // Show notification details after marking as read
      if (mounted) {
        _showNotificationDetails(notification);
      }
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }

  Future<void> _markAsRead(
    String notificationId,
    UserManagementViewModel viewModel,
  ) async {
    await viewModel.markNotificationAsRead(notificationId);
  }

  void _showNotificationDetails(UserNotification notification) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                _getNotificationIcon(notification.type),
                const SizedBox(width: 12),
                Expanded(child: Text(notification.title)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(notification.body),
                  const SizedBox(height: 16),
                  Text(
                    'Received: ${DateFormat('MMM d, yyyy h:mm a').format(notification.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  if (notification.data.isNotEmpty &&
                      notification.data.keys.any(
                        (k) => !['type', 'clickAction'].contains(k),
                      )) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Additional Information',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...notification.data.entries
                        .where((e) => !['type', 'clickAction'].contains(e.key))
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_formatKey(e.key)}: ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    e.value.toString(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  String _formatKey(String key) {
    // Convert camelCase or snake_case to Title Case
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) =>
              word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
  }
}
