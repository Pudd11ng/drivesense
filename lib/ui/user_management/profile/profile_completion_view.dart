import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:drivesense/ui/user_management/view_model/user_management_view_model.dart';
import 'package:drivesense/constants/countries.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:drivesense/ui/core/themes/colors.dart';

class ProfileCompletionView extends StatefulWidget {
  const ProfileCompletionView({super.key});

  @override
  State<ProfileCompletionView> createState() => _ProfileCompletionViewState();
}

class _ProfileCompletionViewState extends State<ProfileCompletionView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedCountry;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Pre-fill email if available from registration
    final viewModel = Provider.of<UserManagementViewModel>(
      context,
      listen: false,
    );
    if (viewModel.user.email.isNotEmpty) {
      _emailController.text = viewModel.user.email;
    }

    // Set default country
    _selectedCountry = "Malaysia";
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with profile avatar
                _buildProfileHeader(isDarkMode, onSurfaceColor),

                const SizedBox(height: 36),

                // Form fields
                _buildFormField(
                  controller: _firstNameController,
                  label: 'First Name',
                  icon: Icons.person_outline,
                  isDarkMode: isDarkMode,
                  primaryColor: primaryColor,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your first name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildFormField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  icon: Icons.person_outline,
                  isDarkMode: isDarkMode,
                  primaryColor: primaryColor,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildFormField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  isDarkMode: isDarkMode,
                  primaryColor: primaryColor,
                  readOnly: true,
                ),
                const SizedBox(height: 16),

                _buildDateField(context, isDarkMode, primaryColor),
                const SizedBox(height: 16),

                _buildCountryField(isDarkMode, primaryColor),
                const SizedBox(height: 40),

                _buildSubmitButton(isDarkMode),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Extracted methods for better organization
  Widget _buildProfileHeader(bool isDarkMode, Color onSurfaceColor) {
    return Center(
      child: Column(
        children: [
          // Avatar with adaptive coloring
          Container(
            height: 110,
            width: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isDarkMode
                      ? AppColors.darkBlue.withValues(alpha: 0.3)
                      : AppColors.blue.withValues(alpha: 0.15),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blackTransparent.withValues(alpha: 0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(
              Icons.person_outline,
              size: 60,
              color: isDarkMode ? AppColors.white : AppColors.darkBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tell us about yourself',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: onSurfaceColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Please provide your personal information\nto complete your profile',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDarkMode,
    required Color primaryColor,
    TextInputType? keyboardType,
    bool readOnly = false,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: Theme.of(context).textTheme.labelLarge,
        prefixIcon: Icon(
          icon,
          color: isDarkMode ? primaryColor : AppColors.darkBlue,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? AppColors.greyBlue : AppColors.whiteGrey,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                isDarkMode
                    ? AppColors.greyBlue.withValues(alpha: 0.5)
                    : AppColors.whiteGrey,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor:
            isDarkMode
                ? AppColors.blackTransparent.withValues(alpha: 0.2)
                : (readOnly
                    ? AppColors.lightGrey.withValues(alpha: 0.7)
                    : AppColors.lightGrey),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        errorStyle: TextStyle(color: Theme.of(context).colorScheme.onError),
      ),
      textCapitalization: textCapitalization,
      keyboardType: keyboardType,
      readOnly: readOnly,
      validator: validator,
      style: TextStyle(
        color:
            isDarkMode
                ? AppColors.white.withValues(alpha: readOnly ? 0.7 : 1.0)
                : AppColors.darkGrey,
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context,
    bool isDarkMode,
    Color primaryColor,
  ) {
    return FormField<DateTime>(
      validator: (value) {
        if (_selectedDate == null) {
          return 'Please select your date of birth';
        }
        return null;
      },
      builder: (FormFieldState<DateTime> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () async {
                await _selectDate(context, isDarkMode);
                state.didChange(_selectedDate);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        state.hasError
                            ? Theme.of(context).colorScheme.error
                            : (isDarkMode
                                ? AppColors.greyBlue.withValues(alpha: 0.5)
                                : AppColors.whiteGrey),
                  ),
                  color:
                      isDarkMode
                          ? AppColors.blackTransparent.withValues(alpha: 0.2)
                          : AppColors.lightGrey,
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Icon(
                        Icons.calendar_today,
                        color:
                            state.hasError
                                ? Theme.of(context).colorScheme.error
                                : (isDarkMode
                                    ? primaryColor
                                    : AppColors.darkBlue),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date of Birth',
                              style: Theme.of(
                                context,
                              ).textTheme.labelSmall?.copyWith(
                                color:
                                    isDarkMode
                                        ? AppColors.greyBlue
                                        : AppColors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedDate != null
                                  ? DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(_selectedDate!)
                                  : 'Select your date of birth',
                              style: TextStyle(
                                color:
                                    _selectedDate == null
                                        ? (isDarkMode
                                            ? AppColors.greyBlue
                                            : AppColors.grey)
                                        : (isDarkMode
                                            ? AppColors.white
                                            : AppColors.black),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_selectedDate != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Icon(
                          Icons.check_circle,
                          color: AppColors.blue,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6.0, left: 12.0),
                child: Text(
                  state.errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                    fontSize: 12.0,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCountryField(bool isDarkMode, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDarkMode
                  ? AppColors.greyBlue.withValues(alpha: 0.5)
                  : AppColors.whiteGrey,
        ),
        color:
            isDarkMode
                ? AppColors.blackTransparent.withValues(alpha: 0.2)
                : AppColors.lightGrey,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Icon(
              Icons.public,
              color: isDarkMode ? primaryColor : AppColors.darkBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownSearch<String>(
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: "Search country",
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDarkMode ? AppColors.white : AppColors.darkBlue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                menuProps: MenuProps(
                  backgroundColor:
                      isDarkMode ? AppColors.black : AppColors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
              ),
              items: (filter, infiniteScrollProps) => countries,
              decoratorProps: DropDownDecoratorProps(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  suffixIcon: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey,
                  ),
                ),
              ),
              dropdownBuilder: (context, selectedItem) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Country',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDarkMode ? AppColors.greyBlue : AppColors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedItem ?? 'Select your country',
                      style: TextStyle(
                        color:
                            selectedItem == null
                                ? (isDarkMode
                                    ? AppColors.greyBlue
                                    : AppColors.grey)
                                : (isDarkMode
                                    ? AppColors.white
                                    : AppColors.black),
                        fontSize: 16,
                      ),
                    ),
                  ],
                );
              },
              onChanged: (value) {
                setState(() {
                  _selectedCountry = value;
                });
              },
              selectedItem: _selectedCountry,
            ),
          ),
          if (_selectedCountry != null)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Icon(Icons.check_circle, color: AppColors.blue, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isDarkMode) {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDarkMode ? AppColors.blue : AppColors.darkBlue,
        disabledBackgroundColor:
            isDarkMode
                ? AppColors.blue.withValues(alpha: 0.5)
                : AppColors.darkBlue.withValues(alpha: 0.5),
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child:
          _isSubmitting
              ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              )
              : Text(
                'Complete Profile',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isDarkMode) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ??
          DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                isDarkMode
                    ? ColorScheme.dark(
                      primary: AppColors.blue,
                      onPrimary: AppColors.white,
                      surface: AppColors.black,
                      onSurface: AppColors.white,
                    )
                    : ColorScheme.light(
                      primary: AppColors.darkBlue,
                      onPrimary: AppColors.white,
                      onSurface: Colors.black,
                    ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _submitProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your date of birth'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      if (_selectedCountry == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your country'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      final viewModel = Provider.of<UserManagementViewModel>(
        context,
        listen: false,
      );

      // Update user profile
      final success = await viewModel.updateUserProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        dateOfBirth: _dobController.text,
        country: _selectedCountry,
      );

      setState(() {
        _isSubmitting = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to home page after successful completion
        context.go('/');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Error Completing Profile',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(viewModel.errorMessage ?? 'Failed to complete profile'),
                ],
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}
