import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/itk_bottom_nav.dart';
import 'edit_profile_page.dart';

class RegisteredEventsPage extends StatelessWidget {
  const RegisteredEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Registered Events'),
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: ItkBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const EditProfilePage()),
            );
          }
        },
      ),
      body: const Center(
        child: Text(
          'Registered Events',
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
