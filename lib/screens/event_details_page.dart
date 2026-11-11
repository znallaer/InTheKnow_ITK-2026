import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../theme/app_colors.dart';

class EventDetailsPage extends StatefulWidget {
  final String eventId;

  const EventDetailsPage({super.key, required this.eventId});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  final _eventService = EventService();
  bool _registering = false;

  Future<void> _handleRegister() async {
    setState(() => _registering = true);
    try {
      await _eventService.registerForEvent(widget.eventId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully registered!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.dark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Image.asset(
              'assets/images/itk_logo.png',
              height: 40,
              errorBuilder: (_, _, _) => const Text(
                'iTK',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.dark,
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<Event?>(
        stream: _eventService.eventStream(widget.eventId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.green),
            );
          }

          final event = snapshot.data!;

          return StreamBuilder<bool>(
            stream: _eventService.isRegistered(widget.eventId),
            builder: (context, regSnap) {
              final isRegistered = regSnap.data ?? false;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 190,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.green, width: 2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: event.imageUrl.isNotEmpty
                          ? Image.network(event.imageUrl, fit: BoxFit.cover)
                          : Image.asset(
                        'assets/images/banner_puzzle.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.cardGreen,
                          child: const Icon(
                            Icons.school,
                            size: 64,
                            color: AppColors.green,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, color: AppColors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${event.dateLabel} ${event.timeLabel}',
                          style: const TextStyle(fontSize: 14, color: AppColors.dark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          event.location,
                          style: const TextStyle(fontSize: 14, color: AppColors.dark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.people_alt, color: AppColors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${event.registeredCount} of ${event.totalSlots} slots registered',
                          style: const TextStyle(fontSize: 14, color: AppColors.dark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'About this event',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description.isNotEmpty
                          ? event.description
                          : 'Learn, Grow, and Connect with fellow campus peers.',
                      style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
                    ),
                    const SizedBox(height: 36),
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isRegistered
                                ? Colors.grey.shade400
                                : AppColors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: (isRegistered || event.isFull || _registering)
                              ? null
                              : _handleRegister,
                          child: _registering
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            isRegistered
                                ? 'Already Registered'
                                : event.isFull
                                ? 'Fully Booked'
                                : 'Register for this Event',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}