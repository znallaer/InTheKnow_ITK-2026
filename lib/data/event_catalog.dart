import '../models/event.dart';

final List<Event> kEventCatalog = [
  Event(
    id: 'flutter-app-development',
    title: 'Flutter App Development',
    category: 'Workshop',
    location: 'Room 807',
    date: DateTime(2026, 6, 8, 13, 0),
    totalSlots: 12,
    imageAsset: 'assets/images/events/flutter_workshop.jpg',
    description:
        'A hands-on session where you build your first mobile app with Flutter. '
        'Bring your laptop and learn widgets, navigation, and Firebase basics '
        'from student developers and faculty mentors.',
  ),
  Event(
    id: 'android-app-development',
    title: 'Android App Development',
    category: 'Seminar',
    location: 'MPR 203',
    date: DateTime(2026, 6, 10, 10, 0),
    totalSlots: 40,
    imageAsset: 'assets/images/events/android_seminar.jpg',
    description:
        'Learn the fundamentals of Android app development, from designing user interfaces to building functional mobile applications. This beginner-friendly seminar introduces essential tools, concepts, and best practices for creating Android apps.',
  ),
  Event(
    id: 'tech-career-talk-2027',
    title: 'Tech Career Talk 2027',
    category: 'Seminar',
    location: 'AVR 2',
    date: DateTime(2027, 6, 22, 9, 0),
    totalSlots: 50,
    imageAsset: 'assets/images/events/tech_career_talk.png',
    description:
        'Learn, Grow, and Connect with fellow IT Personnels and have the '
        'chance to start up your career in tech.',
  ),
  Event(
    id: 'intramurals-basketball',
    title: 'Intramurals Basketball Cup',
    category: 'Sports',
    location: 'Covered Court',
    date: DateTime(2027, 6, 12, 15, 0),
    totalSlots: 40,
    imageAsset: 'assets/images/events/intrams.jpg',
    description:
        'Cheer for your department or join a team in the annual basketball '
        'tournament. Register to reserve your spot as a player or supporter '
        'and wear your department colors.',
  ),
  Event(
    id: 'research-colloquium',
    title: 'Student Research Colloquium',
    category: 'Academic',
    location: 'Library Conference Room',
    date: DateTime(2027, 7, 6, 10, 0),
    totalSlots: 60,
    imageAsset: 'assets/images/events/research.jpg',
    description:
        'Senior students present their capstone and thesis work to the campus '
        'community. Listen in, ask questions, and get ideas for your own '
        'research.',
  ),
];

Event? findEvent(String id) {
  for (final event in kEventCatalog) {
    if (event.id == id) return event;
  }
  return null;
}
