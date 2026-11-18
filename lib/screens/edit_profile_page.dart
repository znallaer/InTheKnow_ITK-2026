import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/itk_bottom_nav.dart';
import 'registered_events_page.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const _roles = ['Student', 'Teacher'];
  static const _countryCodes = ['+63', '+1', '+44', '+61', '+81'];

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _authService = AuthService();
  final _eventService = EventService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String? _role;
  String _countryCode = '+63';
  bool _editing = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _eventService.userProfile().first;
      final user = FirebaseAuth.instance.currentUser;
      final phone = profile?['phoneNumber']?.toString() ?? '';
      if (!mounted) return;
      setState(() {
        _nameController.text = profile?['name']?.toString() ?? '';
        _role = _normaliseRole(profile?['role']?.toString());
        for (final code in _countryCodes) {
          if (phone.startsWith(code)) {
            _countryCode = code;
            break;
          }
        }
        _phoneController.text = phone.startsWith(_countryCode)
            ? phone.substring(_countryCode.length)
            : phone;
        _emailController.text =
            profile?['email']?.toString() ?? user?.email ?? '';
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _normaliseRole(String? role) {
    if (role == null) return null;
    return _roles.cast<String?>().firstWhere(
          (item) => item!.toLowerCase() == role.toLowerCase(),
          orElse: () => null,
        );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || _role == null || phone.isEmpty || email.isEmpty) {
      _snack('Please complete all profile fields.');
      return;
    }

    setState(() => _saving = true);
    try {
      await _authService.updateProfile(
        name: name,
        role: _role!,
        phoneNumber: '$_countryCode$phone',
        email: email,
      );
      if (mounted) {
        setState(() {
          _editing = false;
          _saving = false;
        });
        _snack('Profile updated successfully.');
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _saving = false);
      _snack(error.code == 'requires-recent-login'
          ? 'Please log in again before changing your email.'
          : (error.message ?? 'Could not update profile.'));
    } catch (error) {
      if (mounted) setState(() => _saving = false);
      _snack('Could not update profile: $error');
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account and profile data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await _authService.deleteAccount();
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _saving = false);
      _snack(error.code == 'requires-recent-login'
          ? 'Please log in again before deleting your account.'
          : (error.message ?? 'Could not delete account.'));
    } catch (error) {
      if (mounted) setState(() => _saving = false);
      _snack('Could not delete account: $error');
    }
  }

  void _goHome() => Navigator.popUntil(context, (route) => route.isFirst);

  void _openRegisteredEvents() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RegisteredEventsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: AppDrawer(
        onHome: () {
          Navigator.pop(context);
          _goHome();
        },
        onRegisteredEvents: () {
          Navigator.pop(context);
          _openRegisteredEvents();
        },
        onEditProfile: () => Navigator.pop(context),
        onLogout: () async {
          Navigator.pop(context);
          await _authService.logout();
        },
      ),
      bottomNavigationBar: ItkBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            _goHome();
          } else if (index == 1) {
            _openRegisteredEvents();
          }
        },
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.green))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(40, 16, 40, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 48),
                    const Text(
                      'My Profile',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildProfileCard(),
                    const SizedBox(height: 30),
                    _buildActions(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.menu, color: AppColors.green, size: 38),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Image.asset(
          'assets/images/itk_logo.png',
          height: 56,
          errorBuilder: (_, _, _) => const Text(
            'iTK',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.dark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 28),
      decoration: BoxDecoration(
        color: AppColors.cardGreen,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.green, width: 2),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_circle_rounded,
            size: 170,
            color: AppColors.dark,
          ),
          const SizedBox(height: 12),
          _label('Name'),
          _textField(_nameController, keyboardType: TextInputType.name),
          const SizedBox(height: 24),
          _label('Role'),
          AbsorbPointer(
            absorbing: !_editing,
            child: DropdownButtonFormField<String>(
              initialValue: _role,
              isExpanded: true,
              icon: _chevron(),
              style: const TextStyle(fontSize: 17, color: AppColors.dark),
              decoration: _decoration(),
              items: _roles
                  .map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(role.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _role = value),
            ),
          ),
          const SizedBox(height: 24),
          _label('Phone Number'),
          _phoneField(),
          const SizedBox(height: 24),
          _label('Email Address'),
          _textField(
            _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 20, bottom: 10),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  InputDecoration _decoration() => InputDecoration(
        filled: true,
        fillColor: const Color(0xFFD9F2CB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        enabledBorder: _border,
        focusedBorder: _border,
        disabledBorder: _border,
        border: _border,
      );

  OutlineInputBorder get _border => OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.green, width: 2),
      );

  Widget _textField(
    TextEditingController controller, {
    required TextInputType keyboardType,
  }) {
    return TextField(
      controller: controller,
      readOnly: !_editing,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 17, color: AppColors.dark),
      decoration: _decoration(),
    );
  }

  Widget _chevron() => const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.darkGreen,
        size: 28,
      );

  Widget _phoneField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD9F2CB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.green, width: 2),
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 18),
            child: AbsorbPointer(
              absorbing: !_editing,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _countryCode,
                  icon: _chevron(),
                  dropdownColor: Colors.white,
                  style: const TextStyle(
                    fontSize: 17,
                    color: AppColors.dark,
                  ),
                  items: _countryCodes
                      .map((code) => DropdownMenuItem(
                            value: code,
                            child: Text(code),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _countryCode = value);
                  },
                ),
              ),
            ),
          ),
          Container(
            width: 2,
            height: 30,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppColors.green,
          ),
          Expanded(
            child: TextField(
              controller: _phoneController,
              readOnly: !_editing,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 17, color: AppColors.dark),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(right: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            label: 'EDIT',
            color: AppColors.yellow,
            onPressed: _saving ? null : () => setState(() => _editing = true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(
            label: _saving ? 'SAVING…' : 'SAVE',
            color: AppColors.green,
            onPressed: _saving || !_editing ? null : _save,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(
            label: 'DELETE',
            color: const Color(0xFFEB5757),
            onPressed: _saving ? null : _delete,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.45),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
