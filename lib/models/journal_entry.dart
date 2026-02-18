import 'package:intl/intl.dart';

class JournalEntry {
  final DateTime date;
  final List<String> thoughts; // Multiple thoughts in order

  JournalEntry({
    required this.date,
    required this.thoughts,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'thoughts': thoughts,
    };
  }

  // Create from JSON
  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      date: DateTime.parse(json['date']),
      thoughts: List<String>.from(json['thoughts'] ?? []),
    );
  }

  // Get formatted date string (YYYY-MM-DD)
  String getFormattedDate() {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Get formatted time string (HH:MM)
  String getFormattedTime() {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Get journal name (date-based)
  String getJournalName() {
    return DateFormat('EEEE, MMMM d, yyyy').format(date);
  }

  // Get first thought preview
  String get firstThought => thoughts.isNotEmpty ? thoughts.first : '';

  // Get entry text for compatibility (first thought)
  String get entry => firstThought;

  // Get second line for compatibility
  String? get secondLine => thoughts.length > 1 ? thoughts[1] : null;
}

