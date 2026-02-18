import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/journal_entry.dart';

class JournalStorage {
  static const String _storageKey = 'journal_entries';

  // Save all entries
  Future<void> saveEntries(List<JournalEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = entries.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  // Load all entries
  Future<List<JournalEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null) {
      return [];
    }

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => JournalEntry.fromJson(json)).toList();
  }

  // Add a new entry
  Future<void> addEntry(JournalEntry entry) async {
    final entries = await loadEntries();
    entries.add(entry);
    // Sort by date (newest first)
    entries.sort((a, b) => b.date.compareTo(a.date));
    await saveEntries(entries);
  }

  // Update an entry
  Future<void> updateEntry(int index, JournalEntry entry) async {
    final entries = await loadEntries();
    if (index >= 0 && index < entries.length) {
      entries[index] = entry;
      entries.sort((a, b) => b.date.compareTo(a.date));
      await saveEntries(entries);
    }
  }

  // Delete an entry
  Future<void> deleteEntry(int index) async {
    final entries = await loadEntries();
    if (index >= 0 && index < entries.length) {
      entries.removeAt(index);
      await saveEntries(entries);
    }
  }

  // Get entries for a specific date range
  Future<List<JournalEntry>> getEntriesInRange(DateTime start, DateTime end) async {
    final entries = await loadEntries();
    return entries.where((entry) {
      return entry.date.isAfter(start.subtract(const Duration(days: 1))) &&
             entry.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Get entries for current month
  Future<List<JournalEntry>> getCurrentMonthEntries() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    return getEntriesInRange(start, end);
  }

  // Get entries for current year
  Future<List<JournalEntry>> getCurrentYearEntries() async {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final end = DateTime(now.year, 12, 31);
    return getEntriesInRange(start, end);
  }
}

