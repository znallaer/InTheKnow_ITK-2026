import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/event_service.dart';
import '../theme/app_colors.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onRegisteredEvents;
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;

  const AppDrawer({
    super.key,
    required this.onHome,
    required this.onRegisteredEvents,
    required this.onEditProfile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final authEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.72,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StreamBuilder<Map<String, dynamic>?>(
            stream: EventService().userProfile(),
            builder: (context, snapshot) {
              final data = snapshot.data;
              final storedName = (data?['name'] as String?)?.trim() ?? '';
              final email = (data?['email'] as String?) ?? authEmail;
              final name = storedName.isNotEmpty
                  ? storedName
                  : (email.contains('@') ? email.split('@').first : 'User');
              return _DrawerHeader(name: name, email: email);
            },
          ),
          const SizedBox(height: 16),
          _DrawerItem(icon: Icons.home_outlined, label: 'Home', onTap: onHome),
          _DrawerItem(
            icon: Icons.event_available_outlined,
            label: 'Registered Events',
            onTap: onRegisteredEvents,
          ),
          _DrawerItem(
            icon: Icons.manage_accounts,
            label: 'Edit Profile',
            onTap: onEditProfile,
          ),
          _DrawerItem(icon: Icons.logout, label: 'Log Out', onTap: onLogout),
        ],
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final String name;
  final String email;

  const _DrawerHeader({required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      color: AppColors.green,
      padding: EdgeInsets.fromLTRB(40, topInset + 56, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProfileAvatar(size: 90),
          const SizedBox(height: 26),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 20, 24, 20),
        child: Row(
          children: [
            Icon(icon, color: AppColors.green, size: 36),
            const SizedBox(width: 30),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  final double size;

  const ProfileAvatar({super.key, this.size = 90});

  @override
  Widget build(BuildContext context) {
    final ring = size * 0.065;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: ring),
      ),
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: size * 0.2,
              child: Container(
                width: size * 0.35,
                height: size * 0.35,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -size * 0.22,
              child: Container(
                width: size * 0.68,
                height: size * 0.5,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(size * 0.34),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
