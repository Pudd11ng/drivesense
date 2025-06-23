import 'package:drivesense/ui/user_management/login/login_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:drivesense/ui/user_management/view_model/user_management_view_model.dart';
import 'package:drivesense/ui/core/themes/colors.dart';

class ResetPasswordView extends StatefulWidget {
  final String token;

  const ResetPasswordView({super.key, required this.token});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSuccess = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed:
              () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (context) => LoginView())),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Consumer<UserManagementViewModel>(
            builder: (context, viewModel, child) {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(
                        Theme.of(context).brightness == Brightness.dark
                            ? 'assets/drivesense_logo_white.png'
                            : 'assets/drivesense_logo.png',
                        height: 90,
                        width: 90,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      _isSuccess
                          ? 'Password Reset Successfully'
                          : 'Create New Password',
                      style: Theme.of(context).textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    Text(
                      _isSuccess
                          ? 'Your password has been reset successfully. You can now login with your new password.'
                          : 'Enter and confirm your new password below.',
                      style: Theme.of(context).textTheme.labelLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    if (!_isSuccess) ...[
                      // New Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: AppColors.black),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColors.black,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.black,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          hintText: 'New Password',
                          filled: true,
                          fillColor: AppColors.lightGrey,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          errorStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onError,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          // // Check for at least one uppercase letter
                          // if (!RegExp(r'[A-Z]').hasMatch(value)) {
                          //   return 'Password must contain at least one uppercase letter';
                          // }
                          // // Check for at least one number
                          // if (!RegExp(r'[0-9]').hasMatch(value)) {
                          //   return 'Password must contain at least one number';
                          // }
                          // // Check for at least one special character
                          // if (!RegExp(
                          //   r'[!@#$%^&*(),.?":{}|<>]',
                          // ).hasMatch(value)) {
                          //   return 'Password must contain at least one special character';
                          // }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Confirm Password Field
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: AppColors.black),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColors.black,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.black,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                          hintText: 'Confirm Password',
                          filled: true,
                          fillColor: AppColors.lightGrey,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          errorStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onError,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your new password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 72),

                      // Container(
                      //   padding: const EdgeInsets.all(12),
                      //   decoration: BoxDecoration(
                      //     color:
                      //         Theme.of(context).brightness == Brightness.dark
                      //             ? AppColors.darkGrey.withOpacity(0.3)
                      //             : AppColors.lightGrey.withOpacity(0.5),
                      //     borderRadius: BorderRadius.circular(8),
                      //   ),
                      //   child: Column(
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: [
                      //       Text(
                      //         'Password must:',
                      //         style: Theme.of(context).textTheme.bodySmall
                      //             ?.copyWith(fontWeight: FontWeight.bold),
                      //       ),
                      //       const SizedBox(height: 8),
                      //       Text(
                      //         '• Be at least 8 characters long',
                      //         style: Theme.of(context).textTheme.bodySmall,
                      //       ),
                      //       Text(
                      //         '• Include at least one uppercase letter (A-Z)',
                      //         style: Theme.of(context).textTheme.bodySmall,
                      //       ),
                      //       Text(
                      //         '• Include at least one number (0-9)',
                      //         style: Theme.of(context).textTheme.bodySmall,
                      //       ),
                      //       Text(
                      //         '• Include at least one special character (!@#\$%^&*)',
                      //         style: Theme.of(context).textTheme.bodySmall,
                      //       ),
                      //     ],
                      //   ),
                      // ),

                      // Submit Button
                      ElevatedButton(
                        onPressed: viewModel.isLoading ? null : _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child:
                            viewModel.isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: AppColors.white,
                                  ),
                                )
                                : Text(
                                  'RESET PASSWORD',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ] else ...[
                      // Back to Login Button
                      ElevatedButton(
                        onPressed:
                            () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => LoginView(),
                              ),
                            ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'GO TO LOGIN',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],

                    // Error Message
                    if (viewModel.errorMessage != null && !_isSuccess)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          viewModel.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      final viewModel = Provider.of<UserManagementViewModel>(
        context,
        listen: false,
      );

      final success = await viewModel.resetPassword(
        token: widget.token,
        newPassword: _passwordController.text.trim(),
      );

      if (success && mounted) {
        setState(() {
          _isSuccess = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
