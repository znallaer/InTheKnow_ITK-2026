import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String category;
  final String location;
  final String description;
  final String imageUrl;
  final DateTime date;
  final int totalSlots;
  final int registeredCount;

  const Event({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.description,
    required this.imageUrl,
    required this.date,
    required this.totalSlots,
    required this.registeredCount,
  });

  factory Event.fromDoc(DocumentSnapshot doc) {
  final d = (doc.data() as Map<String, dynamic>?) ?? {};
  return Event(
  id: doc.id,
  title: d['title']?.toString() ?? '',
  category: d['category']?.toString() ?? '',
  location: d['location']?.toString() ?? '',
  description: d['description']?.toString() ?? '',
  imageUrl: d['imageUrl']?.toString() ?? '',
  date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
  totalSlots: (d['totalSlots'] as num?)?.toInt() ?? 0,
  registeredCount: (d['registeredCount'] as num?)?.toInt() ?? 0,
  );
  }

  int get slotsLeft {
  final left = totalSlots - registeredCount;
  return left < 0 ? 0 : left;
  }

  bool get isFull => registeredCount >= totalSlots;

  String get slotsLabel {
  if (isFull) return 'Fully booked';
  return '$slotsLeft slot${slotsLeft == 1 ? '' : 's'} remaining';
  }

  static const List<String> _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String get dateLabel => '${_months[date.month - 1]} ${date.day}, ${date.year}';

  String get timeLabel {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
  }
}