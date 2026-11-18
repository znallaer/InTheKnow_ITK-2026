import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/event.dart';
import '../services/event_service.dart';
import '../theme/app_colors.dart';
import '../widgets/itk_bottom_nav.dart';
import 'edit_profile_page.dart';
import 'registered_events_page.dart';


class EventRegistrationPage extends StatefulWidget {
  final Event event;

  const EventRegistrationPage({super.key, required this.event});

  @override
  State<EventRegistrationPage> createState() => _EventRegistrationPageState();
}

class _EventRegistrationPageState extends State<EventRegistrationPage> {
  static const List<String> _departments = [
    'Computer Science',
    'Information Technology',
    'Artificial Intelligence',
    'Computer Engineering',
    'Business Analytics',
  ];
  static const List<String> _types = ['On-site', 'On-line'];

  static const Color _fieldFill = Color(0xFFD9F2CB);
  static const Color _stepGrey = Color(0xFFC9D1DC);
  static const Color _stepDark = Color(0xFF23282D);

  static const List<String> _weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  final _service = EventService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  int _step = 0;
  String? _department;
  String _type = _types.first;
  DateTime? _attendanceAt;
  bool _agreed = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = FirebaseAuth.instance.currentUser?.email ?? '';
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }


  Future<void> _loadProfile() async {
    try {
      final profile = await _service.userProfile().first;
      if (!mounted) return;
      final name = profile?['name']?.toString() ?? '';
      final email = profile?['email']?.toString() ?? '';
      setState(() {
        if (_nameController.text.isEmpty) _nameController.text = name;
        if (email.isNotEmpty) _emailController.text = email;
      });
    } catch (_) {

    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatAttendance(DateTime d) {
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'pm' : 'am';
    return '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}, '
        '$hour:$minute $period';
  }


  void _goBack() {
    if (_step == 1) {
      setState(() => _step = 0);
    } else {
      Navigator.pop(context);
    }
  }

  void _continueFromInfo() {
    if (_nameController.text.trim().isEmpty) {
      _snack('Please enter your name.');
      return;
    }
    if (_department == null) {
      _snack('Please choose your department.');
      return;
    }
    setState(() => _step = 1);
  }

  Future<void> _pickDateTime() async {
    final result = await showDialog<DateTime>(
      context: context,
      builder: (_) => _DateTimeDialog(
        event: widget.event,
        initial: _attendanceAt ?? widget.event.date,
      ),
    );
    if (result != null && mounted) setState(() => _attendanceAt = result);
  }

  Future<void> _confirm() async {
    if (_attendanceAt == null) {
      _snack('Please choose your attendance date and time.');
      return;
    }
    if (!_agreed) {
      _snack('Please agree to the event guidelines to continue.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await _service.registerForEvent(
        widget.event.id,
        name: _nameController.text,
        department: _department,
        attendanceType: _type,
        attendanceAt: _attendanceAt,
      );
      if (mounted) setState(() => _step = 2);
    } on FirebaseException catch (e) {
      _snack('Registration failed: ${e.message ?? e.code}');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _viewEvents() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RegisteredEventsPage()),
          (route) => route.isFirst,
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: ItkBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisteredEventsPage()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfilePage()),
            );
          }
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Theme(
                data: Theme.of(context).copyWith(canvasColor: Colors.white),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Stepper(
                    type: StepperType.horizontal,
                    currentStep: _step,
                    elevation: 0,
                    stepIconHeight: 44,
                    stepIconWidth: 44,
                    connectorThickness: 2,
                    connectorColor: WidgetStateProperty.all(_stepDark),
                    stepIconBuilder: (index, state) => _stepCircle(index),
                    controlsBuilder: (context, details) =>
                    const SizedBox.shrink(),
                    steps: [
                      Step(
                        title: const SizedBox.shrink(),
                        content: _buildInfoStep(),
                        isActive: _step >= 0,
                      ),
                      Step(
                        title: const SizedBox.shrink(),
                        content: _buildAttendanceStep(),
                        isActive: _step >= 1,
                      ),
                      Step(
                        title: const SizedBox.shrink(),
                        content: _buildDoneStep(),
                        isActive: _step >= 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 16, 40, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.green,
              size: 28,
            ),
            onPressed: _goBack,
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
      ),
    );
  }

  Widget _stepCircle(int index) {
    final active = index <= _step;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.green : _stepGrey,
      ),
      child: Text(
        '${index + 1}',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: active ? Colors.white : _stepDark,
        ),
      ),
    );
  }


  OutlineInputBorder get _border => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.green, width: 2),
  );

  InputDecoration _fieldDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black54, fontSize: 15),
      filled: true,
      fillColor: _fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: _border,
      focusedBorder: _border,
      border: _border,
    );
  }

  Widget _card({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
      decoration: BoxDecoration(
        color: AppColors.cardGreen,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.green, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _chevron() => const Icon(
    Icons.keyboard_arrow_down_rounded,
    color: AppColors.darkGreen,
    size: 32,
  );

  Widget _yellowButton({
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return SizedBox(
      width: 148,
      height: 40,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.yellow,
          disabledBackgroundColor: AppColors.yellow,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onPressed,
        child: loading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }




  Widget _buildInfoStep() {
    return _card(
      title: 'Your Information',
      children: [
        _label('Name'),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(fontSize: 15),
          decoration: _fieldDecoration(hint: 'Name'),
        ),
        const SizedBox(height: 18),
        _label('Email Address'),
        TextField(
          controller: _emailController,
          readOnly: true,
          style: const TextStyle(fontSize: 15),
          decoration: _fieldDecoration(hint: 'Email Address'),
        ),
        const SizedBox(height: 18),
        _label('Department'),
        DropdownButtonFormField<String>(
          initialValue: _department,
          isExpanded: true,
          icon: _chevron(),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(fontSize: 15, color: Colors.black),
          decoration: _fieldDecoration(hint: 'Select department'),
          items: _departments
              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
              .toList(),
          onChanged: (value) => setState(() => _department = value),
        ),
        const SizedBox(height: 26),
        Center(
          child: _yellowButton(label: 'Continue', onPressed: _continueFromInfo),
        ),
      ],
    );
  }


  Widget _buildAttendanceStep() {
    final dateText = _attendanceAt == null
        ? 'MM/DD/YYYY'
        : _formatAttendance(_attendanceAt!);

    return _card(
      title: 'Attendance Options',
      children: [
        _label('Type'),
        DropdownButtonFormField<String>(
          initialValue: _type,
          isExpanded: true,
          icon: _chevron(),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(fontSize: 15, color: Colors.black),
          decoration: _fieldDecoration(),
          items: _types
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _type = value);
          },
        ),
        const SizedBox(height: 18),
        _label('Date'),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _pickDateTime,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            decoration: BoxDecoration(
              color: _fieldFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.green, width: 2),
            ),
            child: Text(
              dateText,
              style: TextStyle(
                fontSize: 15,
                color: _attendanceAt == null ? Colors.black54 : Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        CheckboxListTile(
          value: _agreed,
          onChanged: (value) => setState(() => _agreed = value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.green,
          checkColor: Colors.white,
          side: const BorderSide(color: AppColors.green, width: 2),
          checkboxShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          title: const Text(
            'I agree to the event guidelines and allow my attendance to be recorded.',
            style: TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: _yellowButton(
            label: _agreed ? 'Confirm' : 'Continue',
            loading: _submitting,
            onPressed: _submitting ? null : _confirm,
          ),
        ),
      ],
    );
  }


  Widget _buildDoneStep() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 36),
      decoration: BoxDecoration(
        color: AppColors.cardGreen,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.green, width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_available_outlined, size: 84, color: Colors.black),
          const SizedBox(height: 28),
          const Text(
            'Thank you for Registering!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your spot has been saved.\nA reminder will be sent before the event.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 28),
          _yellowButton(label: 'View Events', onPressed: _viewEvents),
        ],
      ),
    );
  }
}


class _DateTimeDialog extends StatefulWidget {
  final Event event;
  final DateTime initial;

  const _DateTimeDialog({required this.event, required this.initial});

  @override
  State<_DateTimeDialog> createState() => _DateTimeDialogState();
}

class _DateTimeDialogState extends State<_DateTimeDialog> {
  late DateTime _date = DateTime(
    widget.initial.year,
    widget.initial.month,
    widget.initial.day,
  );
  late TimeOfDay _time = TimeOfDay(
    hour: widget.initial.hour,
    minute: widget.initial.minute,
  );

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.cardGreen,
              hourMinuteColor: AppColors.green,
              hourMinuteTextColor: Colors.white,
              dayPeriodColor: WidgetStateColor.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                    ? AppColors.yellow
                    : AppColors.green,
              ),
              dayPeriodTextColor: Colors.white,
              dialBackgroundColor: AppColors.green,
              dialTextColor: Colors.white,
              dialHandColor: Colors.white,
              entryModeIconColor: Colors.black,
              helpTextStyle: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.black),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    final eventDate = widget.event.date;
    return Dialog(
      backgroundColor: AppColors.cardGreen,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 728),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
              child: Theme(
                data: Theme.of(context).copyWith(
                  datePickerTheme: DatePickerThemeData(
                    backgroundColor: AppColors.cardGreen,
                    headerBackgroundColor: AppColors.cardGreen,
                    headerForegroundColor: Colors.black,
                    headerHeadlineStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                    weekdayStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                    ),
                    dayForegroundColor:
                        const WidgetStatePropertyAll(Colors.black),
                    dayBackgroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? AppColors.yellow
                          : Colors.transparent,
                    ),
                    todayForegroundColor:
                        const WidgetStatePropertyAll(AppColors.green),
                    todayBackgroundColor:
                        const WidgetStatePropertyAll(Colors.transparent),
                  ),
                ),
                child: CalendarDatePicker(
                  initialDate: _date,
                  firstDate: DateTime(eventDate.year - 1, eventDate.month),
                  lastDate: DateTime(eventDate.year + 1, eventDate.month + 1, 0),
                  currentDate: DateTime.now(),
                  onDateChanged: (date) => setState(() => _date = date),
                ),
              ),
            ),
          const Divider(height: 1, color: Colors.black87),
          InkWell(
            onTap: _pickTime,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 30, color: Colors.black),
                  const SizedBox(width: 20),
                  const Text(
                    'Set Time',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Text(
                    _time.format(context),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.black87),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.black),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.black),
                  onPressed: () => Navigator.pop(
                    context,
                    DateTime(
                      _date.year,
                      _date.month,
                      _date.day,
                      _time.hour,
                      _time.minute,
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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
}
