import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:drivesense/ui/user_management/view_model/user_management_view_model.dart';
import 'package:drivesense/ui/core/themes/colors.dart';

class InvitationProcessView extends StatefulWidget {
  final String inviteCode;

  const InvitationProcessView({super.key, required this.inviteCode});

  @override
  State<InvitationProcessView> createState() => _InvitationProcessViewState();
}

class _InvitationProcessViewState extends State<InvitationProcessView> {
  bool _processing = true;
  bool _success = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _processInvitation();
  }

  Future<void> _processInvitation() async {
    final viewModel = Provider.of<UserManagementViewModel>(
      context,
      listen: false,
    );

    try {
      final success = await viewModel.acceptEmergencyInvitation(
        widget.inviteCode,
      );

      if (mounted) {
        setState(() {
          _processing = false;
          _success = success;
          if (!success) {
            _errorMessage =
                viewModel.errorMessage ?? 'Failed to process invitation';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _processing = false;
          _success = false;
          _errorMessage = 'An error occurred while processing the invitation';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contact')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _processing
                  ? const CircularProgressIndicator()
                  : Icon(
                    _success ? Icons.check_circle : Icons.error,
                    size: 70,
                    color: _success ? Colors.green : Colors.red,
                  ),
              const SizedBox(height: 24),
              Text(
                _processing
                    ? 'Processing invitation...'
                    : _success
                    ? 'Successfully added as emergency contact'
                    : 'Failed to process invitation',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (!_processing && _errorMessage != null)
                Text(
                  _errorMessage!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              if (!_processing && _success) ...[
                const SizedBox(height: 8),
                Text(
                  'You are now an emergency contact. You\'ll be notified in case of an emergency.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  context.go('/');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDarkMode ? AppColors.blue : AppColors.darkBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
