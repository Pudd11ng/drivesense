import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:drivesense/ui/user_management/view_model/user_management_view_model.dart';
import 'package:drivesense/ui/core/themes/colors.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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
                      'Welcome back',
                      style: Theme.of(context).textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Log in to your account',
                      style: Theme.of(context).textTheme.labelLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

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
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            //TODO: Navigate to the password recovery screen
                          },
                          child: Text(
                            'Forgot password?',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    ElevatedButton(
                      onPressed: viewModel.isLoading ? null : _login,
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
                                width: 20,
                                height: 20,
                                child: const CircularProgressIndicator(
                                  color: AppColors.white,
                                ),
                              )
                              : Text(
                                'LOG IN',
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
                      onPressed: viewModel.isLoading ? null : _googleSignIn,
                      icon: SvgPicture.asset(
                        'assets/google_icon_logo.svg',
                        width: 24,
                        height: 24,
                      ),
                      label: const Text('Sign in with Google'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.lightGrey),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sign Up Option
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Don\'t have an account?'),
                        TextButton(
                          onPressed: () {
                            context.go('/register');
                          },
                          child: Text(
                            'Sign Up',
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

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final viewModel = Provider.of<UserManagementViewModel>(
        context,
        listen: false,
      );
      final success = await viewModel.loginWithEmailPassword(
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

  void _googleSignIn() async {
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
    super.dispose();
  }
}
