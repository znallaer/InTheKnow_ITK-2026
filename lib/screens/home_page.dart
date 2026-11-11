import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '../models/event.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/itk_bottom_nav.dart';
import 'edit_profile_page.dart';
import 'event_details_page.dart';
import 'registered_events_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _eventService = EventService();
  late final Stream<List<Event>> _eventsStream = _eventService.upcomingEvents();

  static const List<String> _categories = [
    'All',
    'Seminar',
    'Workshop',
    'Academic',
    'Sports',
  ];

  String _category = 'All';

  void _openEvent(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailsPage(eventId: event.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: AppDrawer(
        onHome: () => Navigator.pop(context),
        onRegisteredEvents: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisteredEventsPage()),
          );
        },
        onEditProfile: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfilePage()),
          );
        },
        onLogout: () async {
          Navigator.pop(context);
          await AuthService().logout();
        },
      ),
      bottomNavigationBar: ItkBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisteredEventsPage()),
            );
          }
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfilePage()),
            );
          }
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 22),
              _buildBanner(),
              const SizedBox(height: 30),
              _buildSectionTitle(),
              const SizedBox(height: 14),
              _buildChips(),
              const SizedBox(height: 22),
              StreamBuilder<List<Event>>(
                stream: _eventsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text('Could not load events: ${snapshot.error}'),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 152,
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.green),
                      ),
                    );
                  }
                  return _buildCarousel(snapshot.data!);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
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

  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.green, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(4, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 20, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find your next campus experience!',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.only(left: 3),
                    child: Text(
                      'Register for seminars, workshops, sports, and student activities.',
                      style: TextStyle(fontSize: 12.5, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 6,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(14),
                ),
                child: Image.asset(
                  'assets/images/banner_puzzle.png',
                  height: 90,
                  errorBuilder: (_, _, _) => const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      Icons.extension,
                      size: 60,
                      color: AppColors.green,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 0, 50, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Upcoming Events',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _category = 'All'),
            child: const Text(
              'View all',
              style: TextStyle(fontSize: 14, color: AppColors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final label = _categories[index];
          final selected = _category == label;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            showCheckmark: false,
            backgroundColor: Colors.white,
            selectedColor: AppColors.green,
            side: const BorderSide(color: AppColors.green, width: 2),
            shape: const StadiumBorder(),
            labelStyle: TextStyle(
              fontSize: 13,
              color: selected ? Colors.white : Colors.black,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            onSelected: (_) => setState(() => _category = label),
          );
        },
      ),
    );
  }

  Widget _buildCarousel(List<Event> all) {
    final events = _category == 'All'
        ? all
        : all
        .where((e) => e.category.toLowerCase() == _category.toLowerCase())
        .toList();

    if (events.isEmpty) {
      return const SizedBox(
        height: 152,
        child: Center(
          child: Text(
            'No upcoming events here yet.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return CarouselSlider.builder(
      key: ValueKey(_category),
      itemCount: events.length,
      itemBuilder: (context, index, realIndex) {
        final event = events[index];
        return _EventCard(event: event, onTap: () => _openEvent(event));
      },
      options: CarouselOptions(
        height: 152,
        viewportFraction: 0.62,
        enableInfiniteScroll: false,
        enlargeCenterPage: false,
        padEnds: true,
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const _EventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.cardGreen,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.green, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                event.category.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              event.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${event.dateLabel} · ${event.timeLabel} · ${event.location}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, color: Colors.black),
            ),
            const Spacer(),
            Text(
              '● ${event.slotsLabel}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}