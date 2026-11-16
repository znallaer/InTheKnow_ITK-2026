class Event {
  final String id;
  final String title;
  final String category;
  final String location;
  final String description;
  final DateTime date;
  final String imageAsset;
  final String imageUrl;

  final int totalSlots;
  final int registeredCount;

  const Event({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.description,
    required this.date,
    required this.totalSlots,
    this.imageAsset = '',
    this.imageUrl = '',
    this.registeredCount = 0,
  });

  Event withRegisteredCount(int count) => Event(
    id: id,
    title: title,
    category: category,
    location: location,
    description: description,
    date: date,
    totalSlots: totalSlots,
    imageAsset: imageAsset,
    imageUrl: imageUrl,
    registeredCount: count,
  );

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
