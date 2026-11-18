import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/itk_bottom_nav.dart';
import 'edit_profile_page.dart';

class RegisteredEventsPage extends StatefulWidget {
  const RegisteredEventsPage({super.key});

  @override
  State<RegisteredEventsPage> createState() => _RegisteredEventsPageState();
}

class _RegisteredEventsPageState extends State<RegisteredEventsPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _service = EventService();
  late final Stream<List<Map<String, dynamic>>> _eventsStream =
      _service.registeredEvents();

  void _goHome() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );
  }

  Future<void> _setDone(String eventId, bool done) async {
    try {
      await _service.setRegisteredEventDone(eventId, done);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update event: $error')),
      );
    }
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
        onRegisteredEvents: () => Navigator.pop(context),
        onEditProfile: () {
          Navigator.pop(context);
          _openProfile();
        },
        onLogout: () async {
          Navigator.pop(context);
          await AuthService().logout();
        },
      ),
      bottomNavigationBar: ItkBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            _goHome();
          } else if (index == 2) {
            _openProfile();
          }
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _eventsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Could not load registered events: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.green),
                    );
                  }
                  return _buildEventList(snapshot.data!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 40, 0),
      child: Row(
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
      ),
    );
  }

  Widget _buildEventList(List<Map<String, dynamic>> registrations) {
    if (registrations.isEmpty) {
      return const Center(
        child: Text(
          'You have not registered for any events yet.',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 76, 40, 28),
      children: [
        const Text(
          'My Registered Events',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 64),
        ...registrations.map(_buildEventCard),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> registration) {
    final eventId = registration['eventId']?.toString() ?? '';
    final title = registration['title']?.toString() ?? 'Registered event';
    final location = registration['location']?.toString() ?? 'TBA';
    final date = _registeredDate(registration['date']);
    final done = registration['done'] == true;
    final textColor = done ? AppColors.green : AppColors.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.green, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 12,
            offset: Offset(4, 8),
          ),
        ],
      ),
      child: CheckboxListTile(
        value: done,
        onChanged: eventId.isEmpty
            ? null
            : (value) => _setDone(eventId, value ?? false),
        controlAffinity: ListTileControlAffinity.trailing,
        checkboxScaleFactor: 1.45,
        contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        activeColor: AppColors.green,
        checkColor: Colors.white,
        side: const BorderSide(color: AppColors.green, width: 3),
        checkboxShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          '$date · $location',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: textColor, fontSize: 16),
        ),
      ),
    );
  }

  String _registeredDate(dynamic value) {
    DateTime? date;
    if (value is Timestamp) date = value.toDate();
    if (value is DateTime) date = value;
    if (date == null) return 'Date TBA';

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
