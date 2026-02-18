import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/journal_entry.dart';
import '../services/journal_storage.dart';
import '../services/export_service.dart';
import '../providers/theme_provider.dart';
import 'writing_screen.dart';
import 'view_entry_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final JournalStorage _storage = JournalStorage();
  List<JournalEntry> _allEntries = [];
  List<JournalEntry> _recentEntries = [];
  bool _isLoading = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // For history filtering
  DateTimeRange? _selectedDateRange;
  List<JournalEntry> _filteredHistoryEntries = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
    _loadEntries();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    final entries = await _storage.loadEntries();

    // Get current week entries
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final recentEntries = entries.where((entry) {
      return entry.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
             entry.date.isBefore(weekEnd.add(const Duration(days: 1)));
    }).toList();

    setState(() {
      _allEntries = entries;
      _recentEntries = recentEntries;
      _filteredHistoryEntries = entries;
      _isLoading = false;
    });
  }

  Future<void> _showDateRangePicker() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      currentDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: Colors.deepPurple.shade300,
                    onPrimary: Colors.black,
                    surface: const Color(0xFF2A2A2A),
                    onSurface: Colors.white,
                  )
                : ColorScheme.light(
                    primary: Colors.deepPurple.shade400,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _filteredHistoryEntries = _allEntries.where((entry) {
          return entry.date.isAfter(picked.start.subtract(const Duration(days: 1))) &&
                 entry.date.isBefore(picked.end.add(const Duration(days: 1)));
        }).toList();
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDateRange = null;
      _filteredHistoryEntries = _allEntries;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark
                ? const Color(0xFF1E1E1E)
                : Colors.deepPurple.shade400,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'InnerInk',
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF1E1E1E),
                            Colors.deepPurple.shade900.withOpacity(0.6),
                          ]
                        : [
                            Colors.deepPurple.shade400,
                            Colors.purple.shade300,
                          ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Icon(
                        Icons.auto_stories,
                        size: 60,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              // Theme Toggle
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white,
                ),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
                tooltip: isDark ? 'Light Mode' : 'Dark Mode',
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Welcome Card
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                Colors.deepPurple.shade900.withOpacity(0.3),
                                Colors.purple.shade900.withOpacity(0.3),
                              ]
                            : [
                                Colors.deepPurple.shade50,
                                Colors.purple.shade50,
                              ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.deepPurple.shade300
                                    : Colors.deepPurple.shade400,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.edit_note,
                                color: isDark ? Colors.black : Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('EEEE, MMMM d').format(DateTime.now()),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.grey.shade300
                                          : Colors.deepPurple.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ready to reflect?',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.grey.shade500
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WritingScreen(),
                                ),
                              );
                              _loadEntries();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? Colors.deepPurple.shade300
                                  : Colors.deepPurple.shade400,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.create, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Start Writing',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Recent Journals Header (Current Week)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Journals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(This Week: ${_recentEntries.length})',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recent Journal Entries Grid (Current Week)
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _recentEntries.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.book_outlined,
                                size: 60,
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No entries this week',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start writing today!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _buildJournalTile(_recentEntries[index], index, isDark, true);
                          },
                          childCount: _recentEntries.length,
                        ),
                      ),
                    ),

          // History Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${_filteredHistoryEntries.length})',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                    ),
                  ),
                  const Spacer(),
                  // Calendar filter button
                  IconButton(
                    icon: Icon(
                      Icons.calendar_month,
                      color: _selectedDateRange != null
                          ? (isDark ? Colors.deepPurple.shade300 : Colors.deepPurple.shade400)
                          : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                    ),
                    onPressed: _showDateRangePicker,
                    tooltip: 'Filter by date range',
                  ),
                  // Clear filter button
                  if (_selectedDateRange != null)
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                      onPressed: _clearDateFilter,
                      tooltip: 'Clear filter',
                    ),
                ],
              ),
            ),
          ),

          // History Entries Grid
          _filteredHistoryEntries.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Center(
                      child: Text(
                        'No entries found',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // Find the actual index in _allEntries for deletion
                        final entry = _filteredHistoryEntries[index];
                        final actualIndex = _allEntries.indexOf(entry);
                        return _buildJournalTile(entry, actualIndex, isDark, false);
                      },
                      childCount: _filteredHistoryEntries.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildJournalTile(JournalEntry entry, int index, bool isDark, bool isRecent) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewEntryScreen(
              entry: entry,
              onDelete: () {
                _deleteEntry(index);
              },
            ),
          ),
        );
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF2A2A2A),
                      const Color(0xFF1E1E1E),
                    ]
                  : [
                      Colors.white,
                      Colors.grey.shade50,
                    ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.deepPurple.shade900.withOpacity(0.5)
                      : Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  DateFormat('MMM d, yyyy').format(entry.date),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.deepPurple.shade300
                        : Colors.deepPurple.shade700,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Entry Preview - Same design for both Recent and History
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_stories,
                        size: 40,
                        color: isDark
                            ? Colors.deepPurple.shade300.withOpacity(0.5)
                            : Colors.deepPurple.shade400.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.deepPurple.shade900.withOpacity(0.3)
                              : Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${entry.thoughts.length} Thought${entry.thoughts.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.deepPurple.shade300
                                : Colors.deepPurple.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Time and Download
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    entry.getFormattedTime(),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.download,
                      size: 20,
                      color: isDark
                          ? Colors.deepPurple.shade300
                          : Colors.deepPurple.shade400,
                    ),
                    onPressed: () => _exportSingleEntry(entry),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteEntry(int index) async {
    await _storage.deleteEntry(index);
    await _loadEntries();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry deleted')),
      );
    }
  }

  Future<void> _exportSingleEntry(JournalEntry entry) async {
    final exportService = ExportService();

    try {
      await exportService.exportAsExcel(
        [entry],
        'journal_${entry.getFormattedDate()}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry exported successfully!')),
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
}

