import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/journal_entry.dart';
import '../services/journal_storage.dart';
import '../providers/theme_provider.dart';

class WritingScreen extends StatefulWidget {
  const WritingScreen({super.key});

  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen> {
  final List<TextEditingController> _thoughtControllers = [TextEditingController()];
  final JournalStorage _storage = JournalStorage();

  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _thoughtControllers[0].addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  void _addThoughtField() {
    setState(() {
      final newController = TextEditingController();
      newController.addListener(_onTextChanged);
      _thoughtControllers.add(newController);
    });
  }

  void _removeThoughtField(int index) {
    if (_thoughtControllers.length > 1) {
      setState(() {
        _thoughtControllers[index].dispose();
        _thoughtControllers.removeAt(index);
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _thoughtControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveTemporarily() async {
    setState(() {
      _hasUnsavedChanges = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Saved temporarily'),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _saveAndExit() async {
    // Get all non-empty thoughts
    final thoughts = _thoughtControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (thoughts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write at least one thought before saving'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final entry = JournalEntry(
      date: DateTime.now(),
      thoughts: thoughts,
    );

    await _storage.addEntry(entry);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Entry saved to journal'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Wait a bit to show the success message
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to save before exiting?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
              _saveTemporarily();
            },
            child: const Text('Save Temporarily'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context, false);
              await _saveAndExit();
            },
            child: const Text('Save & Exit'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.deepPurple.shade400,
          elevation: 0,
          actions: [
            // Theme Toggle
            IconButton(
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                themeProvider.toggleTheme();
              },
              tooltip: isDark ? 'Light Mode' : 'Dark Mode',
            ),
            // Word Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.deepPurple.shade900.withOpacity(0.5)
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_thoughtControllers.fold<int>(0, (sum, controller) => sum + controller.text.split(' ').where((word) => word.isNotEmpty).length)} words',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF1E1E1E),
                      const Color(0xFF121212),
                    ]
                  : [
                      Colors.deepPurple.shade50,
                      Colors.white,
                    ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Writing Area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Prompt
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.deepPurple.shade900.withOpacity(0.3)
                                : Colors.deepPurple.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.deepPurple.shade700
                                  : Colors.deepPurple.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: isDark
                                    ? Colors.deepPurple.shade300
                                    : Colors.deepPurple.shade400,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'What made today meaningful?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Dynamic Thought Fields
                        ...List.generate(_thoughtControllers.length, (index) {
                          return Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Thought number badge
                                  Container(
                                    margin: const EdgeInsets.only(top: 12, right: 12),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.deepPurple.shade900.withOpacity(0.5)
                                          : Colors.deepPurple.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.deepPurple.shade300
                                            : Colors.deepPurple.shade700,
                                      ),
                                    ),
                                  ),
                                  // Text field
                                  Expanded(
                                    child: TextField(
                                      controller: _thoughtControllers[index],
                                      maxLines: index == 0 ? 8 : 5,
                                      autofocus: index == 0,
                                      style: TextStyle(
                                        fontSize: 18,
                                        height: 1.6,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: index == 0
                                            ? 'Start writing your first thought...'
                                            : 'Add another thought...',
                                        hintStyle: TextStyle(
                                          color: isDark
                                              ? Colors.grey.shade600
                                              : Colors.grey.shade400,
                                          fontSize: 16,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? Colors.grey.shade800
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? Colors.grey.shade800
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? Colors.deepPurple.shade300
                                                : Colors.deepPurple.shade400,
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: isDark
                                            ? const Color(0xFF2A2A2A)
                                            : Colors.white,
                                        contentPadding: const EdgeInsets.all(16),
                                      ),
                                    ),
                                  ),
                                  // Remove button (if more than one thought)
                                  if (_thoughtControllers.length > 1 && index > 0)
                                    IconButton(
                                      icon: Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.red.shade400,
                                      ),
                                      onPressed: () => _removeThoughtField(index),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        }),

                        // Add Another Thought Button
                        TextButton.icon(
                          onPressed: _addThoughtField,
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: const Text('Add Another Thought'),
                          style: TextButton.styleFrom(
                            foregroundColor: isDark
                                ? Colors.deepPurple.shade300
                                : Colors.deepPurple.shade400,
                          ),
                        ),

                        const SizedBox(height: 100), // Space for bottom buttons
                      ],
                    ),
                  ),
                ),

                // Bottom Action Buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Temporary Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _saveTemporarily,
                          icon: const Icon(Icons.save_outlined, size: 20),
                          label: const Text(
                            'Save Temporarily',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark
                                ? Colors.deepPurple.shade300
                                : Colors.deepPurple.shade400,
                            side: BorderSide(
                              color: isDark
                                  ? Colors.deepPurple.shade300
                                  : Colors.deepPurple.shade400,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Save & Exit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _saveAndExit,
                          icon: const Icon(Icons.check, size: 20),
                          label: const Text(
                            'Save & Exit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.deepPurple.shade300
                                : Colors.deepPurple.shade400,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

