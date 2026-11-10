import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  final _authService = AuthService();

  static const List<String> _roles = ['Student', 'Teacher'];
  static const List<String> _countryCodes = ['+63'];

  String? _selectedRole;
  String _countryCode = '+63';
  bool _obscurePassword = true;
  bool _loading = false;

  static const Color _borderGreen = Color(0xFF16A34A);
  static const Color _labelGreen = Color(0xFF0F7B3F);
  static const Color _yellow = Color(0xFFFAB800);
  static const Color _darkText = Color(0xFF0B1220);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final role = _selectedRole ?? '';
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty ||
        role.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _authService.register(
        name: name,
        role: role,
        email: email,
        phoneNumber: phone,
        password: password,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  OutlineInputBorder get _border => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: _borderGreen, width: 1.5),
  );

  InputDecoration _fieldDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      labelStyle: const TextStyle(color: _labelGreen, fontSize: 16),
      enabledBorder: _border,
      focusedBorder: _border,
      border: _border,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _chevron() => const Icon(
    Icons.keyboard_arrow_down,
    color: _labelGreen,
    size: 28,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),


              Image.asset(
                'assets/images/itk_logo.png',
                height: 60,
                errorBuilder: (_, __, ___) => const Text(
                  'iTK',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: _darkText,
                  ),
                ),
              ),

              const SizedBox(height: 16),


              Center(
                child: Image.asset(
                  'assets/images/campus_banner.png',
                  width: 250,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    width: 250,
                    color: Colors.green.shade50,
                    child: const Icon(Icons.school, size: 80, color: _borderGreen),
                  ),
                ),
              ),


              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _darkText,
                        letterSpacing: -0.3,
                      ),
                      children: [
                        TextSpan(text: 'We saved you a spot. '),
                        TextSpan(
                          text: 'Get in the know.',
                          style: TextStyle(color: _borderGreen),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),


              const Text(
                'Register',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: _darkText,
                ),
              ),

              const SizedBox(height: 16),


              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      style: const TextStyle(fontSize: 16, color: _darkText),
                      decoration: _fieldDecoration('Name'),
                    ),
                  ),
                  const SizedBox(width: 36),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedRole,
                      isExpanded: true,
                      icon: _chevron(),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      style: const TextStyle(fontSize: 16, color: _darkText),
                      decoration: _fieldDecoration('Role'),
                      items: _roles
                          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedRole = value),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),


              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 16, color: _darkText),
                decoration: _fieldDecoration('Email'),
              ),

              const SizedBox(height: 18),


              Container(
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _borderGreen, width: 1.5),
                ),
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  children: [
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _countryCode,
                        icon: _chevron(),
                        dropdownColor: Colors.white,
                        style: const TextStyle(fontSize: 16, color: _labelGreen),
                        items: _countryCodes
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _countryCode = value);
                        },
                      ),
                    ),
                    Container(
                      width: 1.5,
                      height: 30,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: _borderGreen,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontSize: 16, color: _darkText),
                        decoration: const InputDecoration(
                          hintText: 'Phone Number',
                          hintStyle: TextStyle(color: _labelGreen, fontSize: 16),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.only(right: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),


              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(fontSize: 16, color: _darkText),
                decoration: _fieldDecoration(
                  'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: _borderGreen,
                      size: 28,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),

              const SizedBox(height: 28),


              Center(
                child: SizedBox(
                  width: 200,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _yellow,
                      disabledBackgroundColor: _yellow.withOpacity(0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _loading ? null : _handleRegister,
                    child: _loading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      'Register',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}