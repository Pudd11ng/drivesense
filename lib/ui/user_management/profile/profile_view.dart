import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:drivesense/ui/user_management/view_model/user_management_view_model.dart';
import 'package:drivesense/domain/models/user/user.dart';
import 'package:drivesense/constants/countries.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:drivesense/ui/core/widgets/app_header_bar.dart';
import 'package:drivesense/ui/core/themes/colors.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _dobController;
  String? _selectedCountry;
  DateTime? _selectedDate;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _dobController = TextEditingController();
  }

  void _initializeData(User user) {
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _emailController.text = user.email;
    _dobController.text = user.dateOfBirth;
    _selectedCountry = user.country;

    try {
      if (user.dateOfBirth.isNotEmpty) {
        _selectedDate = DateFormat('yyyy-MM-dd').parse(user.dateOfBirth);
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }
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
    return Consumer<UserManagementViewModel>(
      builder: (context, viewModel, child) {
        final user = viewModel.user;

        if (_firstNameController.text.isEmpty) {
          _initializeData(user);
        }

        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final primaryColor = Theme.of(context).colorScheme.primary;

        return Scaffold(
          appBar: AppHeaderBar(
            title: 'Profile',
            leading: Icon(Icons.arrow_back),
            onLeadingPressed: () => context.go('/settings'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildProfileHeader(user, isDarkMode),
                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
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
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        _buildDateField(context, isDarkMode, primaryColor),
                        const SizedBox(height: 16),

                        _buildCountryField(isDarkMode, primaryColor),
                        const SizedBox(height: 30),

                        _buildSaveButton(isDarkMode, viewModel),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(User user, bool isDarkMode) {
    return Container(
      width: double.infinity,
      height: 100,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkBlue, AppColors.blue],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackTransparent.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Background patterns
            Positioned(
              right: -15,
              top: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -40,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              left: 60,
              top: 60,
              child: Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            // Optional: Add subtle dots pattern
            for (int i = 0; i < 5; i++)
              Positioned(
                left: 20.0 + (i * 15),
                bottom: 10,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),

            // Content on top of patterns
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Text greeting
                  Expanded(
                    child: Text(
                      'Hi, ${user.firstName}',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Editable form widgets
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        filled: true,
        fillColor:
            isDarkMode
                ? AppColors.blackTransparent.withValues(alpha: 0.2)
                : (readOnly
                    ? AppColors.lightGrey.withValues(alpha: 0.7)
                    : AppColors.lightGrey),
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
      initialValue: _selectedDate,
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
                    color: Theme.of(context).colorScheme.error,
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

  Widget _buildSaveButton(bool isDarkMode, UserManagementViewModel viewModel) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _saveProfile(viewModel),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDarkMode ? AppColors.blue : AppColors.darkBlue,
          disabledBackgroundColor:
              isDarkMode
                  ? AppColors.blue.withValues(alpha: 0.5)
                  : AppColors.darkBlue.withValues(alpha: 0.5),
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child:
            _isLoading
                ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.white,
                    strokeWidth: 2,
                  ),
                )
                : Text(
                  'Save Changes',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                  ),
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

  void _saveProfile(UserManagementViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) {
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
      _isLoading = true;
    });

    final success = await viewModel.updateUserProfile(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      dateOfBirth: _dobController.text,
      country: _selectedCountry,
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
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
                  'Error Updating Profile',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(viewModel.errorMessage ?? 'Failed to update profile'),
              ],
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}
