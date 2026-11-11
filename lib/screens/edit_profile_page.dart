import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/itk_bottom_nav.dart';
import 'registered_events_page.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: ItkBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RegisteredEventsPage()),
            );
          }
        },
      ),
      body: const Center(
        child: Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.dark,
          ),
        ),
      ),
    );
  }
}
