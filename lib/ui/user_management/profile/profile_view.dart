import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drivesense/ui/user_management/view_model/user_management_view_model.dart';
import 'package:drivesense/domain/models/user/user.dart';
import 'package:go_router/go_router.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  // TODO: delete this after load user data from backend
  @override
  void initState() {
    super.initState();
    Provider.of<UserManagementViewModel>(context, listen: false).loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserManagementViewModel>(
      builder: (context, viewModel, child) {
        final user = viewModel.user;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile', style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(user),
                const SizedBox(height: 20),
                _buildProfileFields(user),
                const SizedBox(height: 30),
                _buildEditButton(context, viewModel, user),
              ],
            ),
          ),
          bottomNavigationBar: BottomAppBar(
            color: const Color(0xFF8C9EF0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.home, color: Colors.white),
                  onPressed: () {
                    context.go('/');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.person, color: Colors.white),
                  onPressed: () {
                    // Already on profile page
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(User user) {
    return Container(
      width: double.infinity,
      height: 100,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 160,
              decoration: BoxDecoration(
                color: const Color(0xFF4DB6AC),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Hi, ${user.firstName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileFields(User user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('First Name'),
          _buildFieldDisplay(user.firstName),
          const SizedBox(height: 16),

          _buildFieldLabel('Last Name'),
          _buildFieldDisplay(user.lastName),
          const SizedBox(height: 16),

          _buildFieldLabel('Email'),
          _buildFieldDisplay(user.email),
          const SizedBox(height: 16),

          _buildFieldLabel('Date of Birth'),
          _buildFieldDisplay(user.dateOfBirth),
          const SizedBox(height: 16),

          _buildFieldLabel('Country/Region'),
          _buildFieldDisplay(user.country),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
    );
  }

  Widget _buildFieldDisplay(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value,
        style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
      ),
    );
  }

  Widget _buildEditButton(
    BuildContext context,
    UserManagementViewModel viewModel,
    User user,
  ) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          _showEditProfileDialog(context, viewModel, user);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A237E),
          minimumSize: const Size(140, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Edit profile',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    UserManagementViewModel viewModel,
    User user,
  ) {
    final firstNameController = TextEditingController(text: user.firstName);
    final lastNameController = TextEditingController(text: user.lastName);
    final emailController = TextEditingController(text: user.email);
    final dobController = TextEditingController(text: user.dateOfBirth);
    final countryController = TextEditingController(text: user.country);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Profile'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                  ),
                  TextField(
                    controller: lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                  ),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  TextField(
                    controller: dobController,
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth (DD/MM/YYYY)',
                    ),
                    keyboardType: TextInputType.datetime,
                  ),
                  TextField(
                    controller: countryController,
                    decoration: const InputDecoration(
                      labelText: 'Country/Region',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  viewModel.updateUserProfile(
                    firstName: firstNameController.text,
                    lastName: lastNameController.text,
                    email: emailController.text,
                    dateOfBirth: dobController.text,
                    country: countryController.text,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }
}
