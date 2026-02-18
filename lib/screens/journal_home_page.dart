import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/journal_entry.dart';
import '../services/journal_storage.dart';
import '../services/export_service.dart';

class JournalHomePage extends StatefulWidget {
  const JournalHomePage({super.key});

  @override
  State<JournalHomePage> createState() => _JournalHomePageState();
}

class _JournalHomePageState extends State<JournalHomePage> {
  final TextEditingController _entryController = TextEditingController();
  final TextEditingController _secondLineController = TextEditingController();
  final JournalStorage _storage = JournalStorage();
  final ExportService _exportService = ExportService();
  List<JournalEntry> _entries = [];
  bool _isLoading = true;
  bool _showSecondLine = false;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    final entries = await _storage.loadEntries();
    setState(() {
      _entries = entries;
      _isLoading = false;
    });
  }

  Future<void> _addEntry() async {
    if (_entryController.text.trim().isEmpty) {
      return;
    }

    // Collect thoughts
    List<String> thoughts = [_entryController.text.trim()];
    if (_showSecondLine && _secondLineController.text.trim().isNotEmpty) {
      thoughts.add(_secondLineController.text.trim());
    }

    final entry = JournalEntry(
      date: DateTime.now(),
      thoughts: thoughts,
    );

    await _storage.addEntry(entry);
    _entryController.clear();
    _secondLineController.clear();
    setState(() => _showSecondLine = false);
    await _loadEntries();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entry saved ✓'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteEntry(int index) async {
    await _storage.deleteEntry(index);
    await _loadEntries();
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Export Journal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Current Month'),
                onTap: () {
                  Navigator.pop(context);
                  _exportRange('month');
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_view_month),
                title: const Text('Current Year'),
                onTap: () {
                  Navigator.pop(context);
                  _exportRange('year');
                },
              ),
              ListTile(
                leading: const Icon(Icons.all_inclusive),
                title: const Text('All Entries'),
                onTap: () {
                  Navigator.pop(context);
                  _exportRange('all');
                },
              ),
              ListTile(
                leading: const Icon(Icons.date_range),
                title: const Text('Custom Range'),
                onTap: () {
                  Navigator.pop(context);
                  _selectCustomRange();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportRange(String range) async {
    List<JournalEntry> entriesToExport;

    switch (range) {
      case 'month':
        entriesToExport = await _storage.getCurrentMonthEntries();
        break;
      case 'year':
        entriesToExport = await _storage.getCurrentYearEntries();
        break;
      case 'all':
        entriesToExport = _entries;
        break;
      default:
        entriesToExport = _entries;
    }

    if (entriesToExport.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No entries to export')),
        );
      }
      return;
    }

    _showExportFormatDialog(entriesToExport, range);
  }

  void _showExportFormatDialog(List<JournalEntry> entries, String range) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Export Format'),
          content: const Text('Choose export format:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _performExport(entries, range, 'csv');
              },
              child: const Text('CSV'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _performExport(entries, range, 'excel');
              },
              child: const Text('Excel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performExport(
      List<JournalEntry> entries, String range, String format) async {
    try {
      final filename = _exportService.generateFilename('innerink_$range');

      if (format == 'csv') {
        await _exportService.exportAsCSV(entries, filename);
      } else {
        await _exportService.exportAsExcel(entries, filename);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported ${entries.length} entries')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _selectCustomRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.deepPurple.shade300,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final entries = await _storage.getEntriesInRange(picked.start, picked.end);
      if (entries.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No entries in selected range')),
          );
        }
        return;
      }
      _showExportFormatDialog(entries, 'custom');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('InnerInk', style: TextStyle(fontWeight: FontWeight.w300)),
        backgroundColor: Colors.deepPurple.shade300,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _showExportOptions,
            tooltip: 'Export',
          ),
        ],
      ),
      body: Column(
        children: [
          // Entry Input Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _entryController,
                  decoration: InputDecoration(
                    hintText: 'What made today meaningful?',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.deepPurple.shade300, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                if (_showSecondLine) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _secondLineController,
                    decoration: InputDecoration(
                      hintText: 'Add another thought... (optional)',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.deepPurple.shade300, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (!_showSecondLine)
                      TextButton.icon(
                        onPressed: () => setState(() => _showSecondLine = true),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add second line'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.deepPurple.shade300,
                        ),
                      ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _addEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple.shade300,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Entries List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_stories, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'No entries yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start your journal by writing your first entry',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _entries.length,
                        itemBuilder: (context, index) {
                          final entry = _entries[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        entry.getFormattedDate(),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.deepPurple.shade300,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        entry.getFormattedTime(),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline,
                                            color: Colors.grey.shade400, size: 20),
                                        onPressed: () => _showDeleteConfirmation(index),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    entry.entry,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.5,
                                    ),
                                  ),
                                  if (entry.secondLine != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      entry.secondLine!,
                                      style: TextStyle(
                                        fontSize: 15,
                                        height: 1.5,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Entry'),
          content: const Text('Are you sure you want to delete this entry?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteEntry(index);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _secondLineController.dispose();
    super.dispose();
  }
}

