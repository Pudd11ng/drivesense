import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:drivesense/ui/user_management/view_model/user_management_view_model.dart';
import 'package:drivesense/ui/core/widgets/app_header_bar.dart';
import 'package:drivesense/ui/core/themes/colors.dart';
import 'package:drivesense/domain/models/user/user.dart';

class EmergencyContactView extends StatefulWidget {
  const EmergencyContactView({super.key});

  @override
  State<EmergencyContactView> createState() => _EmergencyContactViewState();
}

class _EmergencyContactViewState extends State<EmergencyContactView> {
  bool _isGeneratingLink = false;
  String? _generatedLink;

  @override
  void initState() {
    super.initState();
    _loadEmergencyContacts();
  }

  Future<void> _loadEmergencyContacts() async {
    final viewModel = Provider.of<UserManagementViewModel>(
      context,
      listen: false,
    );
    await viewModel.fetchEmergencyContacts();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.black : AppColors.white;
    final textColor = isDarkMode ? AppColors.white : AppColors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppHeaderBar(
        title: 'Emergency Contacts',
        leading: Icon(Icons.arrow_back),
        onLeadingPressed: () => context.go('/'),
      ),
      body: Consumer<UserManagementViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    viewModel.errorMessage!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: textColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadEmergencyContacts,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDarkMode ? AppColors.blue : AppColors.darkBlue,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description and share invitation section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency contacts will be notified in case of an accident detection.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: textColor),
                    ),
                    const SizedBox(height: 24),

                    // Invite button
                    InkWell(
                      onTap:
                          _isGeneratingLink
                              ? null
                              : () =>
                                  _generateInvitationLink(context, viewModel),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors:
                                isDarkMode
                                    ? [
                                      AppColors.blue,
                                      AppColors.blue.withValues(alpha: 0.7),
                                    ]
                                    : [AppColors.darkBlue, AppColors.blue],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child:
                              _isGeneratingLink
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.share,
                                        color: AppColors.white,
                                        size: 22,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'INVITE NEW CONTACT',
                                        style: TextStyle(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Contact list header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  'Your Emergency Contacts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Contact list
              Expanded(
                child:
                    viewModel.emergencyContacts.isEmpty
                        ? _buildEmptyState(context, isDarkMode)
                        : ListView.builder(
                          itemCount: viewModel.emergencyContacts.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            final contact = viewModel.emergencyContacts[index];
                            return _buildContactCard(
                              context,
                              contact,
                              isDarkMode,
                              viewModel,
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _generateInvitationLink(
    BuildContext context,
    UserManagementViewModel viewModel,
  ) async {
    setState(() {
      _isGeneratingLink = true;
    });

    try {
      final inviteLink = await viewModel.generateInvitationCode();

      setState(() {
        _isGeneratingLink = false;
        _generatedLink = inviteLink;
      });

      // Show the invite dialog
      if (mounted) {
        _showInviteDialog(context);
      }
    } catch (e) {
      setState(() {
        _isGeneratingLink = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildEmptyState(BuildContext context, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.contact_emergency,
            size: 64,
            color:
                isDarkMode
                    ? AppColors.greyBlue.withValues(alpha: 0.5)
                    : AppColors.greyBlue,
          ),
          const SizedBox(height: 16),
          Text(
            'No emergency contacts',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color:
                  isDarkMode
                      ? AppColors.greyBlue.withValues(alpha: 0.5)
                      : AppColors.greyBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Invite contacts who should be notified\nin case of an emergency',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color:
                  isDarkMode
                      ? AppColors.greyBlue.withValues(alpha: 0.3)
                      : AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    User contact,
    bool isDarkMode,
    UserManagementViewModel viewModel,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDarkMode
                  ? [Color(0xFF2D3748), Color(0xFF1A202C)]
                  : [Color(0xFF64748B), Color(0xFF334155)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackTransparent.withValues(alpha: 
              isDarkMode ? 0.3 : 0.1,
            ),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.contact_emergency,
                color: AppColors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${contact.firstName} ${contact.lastName}',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.email,
                        size: 14,
                        color: AppColors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        contact.email,
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed:
                  () => _showRemoveContactDialog(context, contact, viewModel),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    if (_generatedLink == null) return;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final inviteLink = _generatedLink!;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? AppColors.black : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite Emergency Contact',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? AppColors.white : AppColors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Share this link with someone to make them your emergency contact. They\'ll need to have the DriveSense app installed.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDarkMode ? AppColors.white : AppColors.black,
                  ),
                ),
                const SizedBox(height: 24),

                // Link display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          inviteLink,
                          style: TextStyle(
                            color:
                                isDarkMode ? AppColors.white : AppColors.black,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        color: isDarkMode ? AppColors.blue : AppColors.darkBlue,
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: inviteLink),
                          ).then((_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Invitation link copied to clipboard',
                                ),
                              ),
                            );
                            Navigator.pop(context);
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Share.share(
                            'I\'d like to add you as my emergency contact in DriveSense. Please install the app and tap this link: $inviteLink',
                            subject: 'DriveSense Emergency Contact Invitation',
                          );
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Share Link'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDarkMode ? AppColors.blue : AppColors.darkBlue,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  void _showRemoveContactDialog(
    BuildContext context,
    User contact,
    UserManagementViewModel viewModel,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Contact'),
            backgroundColor: isDarkMode ? AppColors.black : AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Text(
              'Are you sure you want to remove ${contact.firstName} ${contact.lastName} as your emergency contact?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDarkMode ? AppColors.greyBlue : AppColors.darkGrey,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final success = await viewModel.removeEmergencyContact(
                    contact.userId,
                  );

                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contact removed successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          viewModel.errorMessage ?? 'Failed to remove contact',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }
}
