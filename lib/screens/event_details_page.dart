import 'package:flutter/material.dart';

import '../models/event.dart';
import '../services/event_service.dart';
import '../theme/app_colors.dart';
import '../widgets/event_cover.dart';
import '../widgets/itk_bottom_nav.dart';
import 'edit_profile_page.dart';
import 'event_registration_page.dart';
import 'registered_events_page.dart';

class EventDetailsPage extends StatefulWidget {
  final String eventId;

  const EventDetailsPage({super.key, required this.eventId});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  final _service = EventService();
  late final Stream<Event?> _eventStream = _service.eventStream(widget.eventId);
  late final Stream<bool> _registeredStream =
  _service.isRegistered(widget.eventId);

  void _openRegistration(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventRegistrationPage(event: event)),
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
        child: StreamBuilder<Event?>(
          stream: _eventStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('Could not load event: ${snapshot.error}'),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.green),
              );
            }
            final event = snapshot.data;
            if (event == null) {
              return const Center(child: Text('This event no longer exists.'));
            }
            return _buildContent(event);
          },
        ),
      ),
    );
  }

  Widget _buildContent(Event event) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back arrow + logo
          Padding(
            padding: const EdgeInsets.only(top: 16),
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
                  onPressed: () => Navigator.pop(context),
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
          ),
          const SizedBox(height: 20),


          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.green, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(4, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: EventCover(event: event, height: 200),
            ),
          ),
          const SizedBox(height: 26),


          Text(
            event.title,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '📅 ${event.dateLabel} · ${event.timeLabel}',
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          Text(
            '📍 ${event.location}',
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          Text(
            '👥 ${event.registeredCount} of ${event.totalSlots} slots registered',
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 20),


          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: AppColors.cardGreen,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.green, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About this event',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                Text(
                  event.description,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(fontSize: 14, height: 1.45),
                ),
                const SizedBox(height: 14),
                Center(child: _buildRegisterButton(event)),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRegisterButton(Event event) {
    return StreamBuilder<bool>(
      stream: _registeredStream,
      builder: (context, snapshot) {
        final registered = snapshot.data ?? false;
        final full = event.isFull && !registered;

        String label;
        Color color;
        if (registered) {
          label = "You're registered ✓";
          color = AppColors.green;
        } else if (full) {
          label = 'Fully booked';
          color = Colors.grey;
        } else {
          label = 'Register for this Event';
          color = AppColors.yellow;
        }

        final canTap = !registered && !full;

        return SizedBox(
          height: 42,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              disabledBackgroundColor: color,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: canTap ? () => _openRegistration(event) : null,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}