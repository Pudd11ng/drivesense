import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:drivesense/ui/user_management/view_model/user_management_view_model.dart';
import 'package:drivesense/ui/core/themes/colors.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    const SizedBox(height: 10),

                    Text(
                      'Create Account',
                      style: Theme.of(context).textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Email TextField
                    TextFormField(
                      controller: _emailController,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: AppColors.black),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: AppColors.black,
                        ),
                        hintText: 'Email',
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
                          return 'Please enter your email';
                        }
                        // TODO: Add email validation regex
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password TextField
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: AppColors.black),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppColors.black,
                        ),
                        hintText: 'Password',
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
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password TextField
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: AppColors.black),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppColors.black,
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
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Register Button
                    ElevatedButton(
                      onPressed: viewModel.isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkBlue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child:
                          viewModel.isLoading
                              ? SizedBox(
                                height: 20,
                                width: 20,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                              : Text(
                                'SIGN UP',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),

                    // Error Message
                    if (viewModel.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          viewModel.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onError,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Divider or Separator
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? AppColors.whiteGrey
                                    : AppColors.lightGrey,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'Or',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.light
                                      ? AppColors.grey
                                      : AppColors.lightGrey,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? AppColors.whiteGrey
                                    : AppColors.lightGrey,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Google Sign-In Button
                    OutlinedButton.icon(
                      onPressed: viewModel.isLoading ? null : _googleSignUp,
                      icon: SvgPicture.asset(
                        'assets/google_icon_logo.svg',
                        width: 24,
                        height: 24,
                      ),
                      label: const Text('Sign up with Google'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.lightGrey),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sign In Option
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account?'),
                        TextButton(
                          onPressed: () {
                            context.go('/login');
                          },
                          child: Text(
                            'Sign In',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: AppColors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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

  void _register() async {
    if (_formKey.currentState!.validate()) {
      final viewModel = Provider.of<UserManagementViewModel>(
        context,
        listen: false,
      );
      final success = await viewModel.registerWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (success && mounted) {
        if (viewModel.needsProfileCompletion) {
          context.go('/profile_completion');
        } else {
          context.go('/');
        }
      }
    }
  }

  void _googleSignUp() async {
    final viewModel = Provider.of<UserManagementViewModel>(
      context,
      listen: false,
    );
    final success = await viewModel.signInWithGoogle();

    if (success && mounted) {
      if (viewModel.needsProfileCompletion) {
        context.go('/profile_completion');
      } else {
        context.go('/');
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
