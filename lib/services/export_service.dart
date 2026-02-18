import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/journal_entry.dart';

class ExportService {
  // Export entries as CSV
  Future<void> exportAsCSV(List<JournalEntry> entries, String filename) async {
    // Prepare CSV data
    List<List<dynamic>> rows = [
      ['Date', 'Time', 'Entry', 'Second Line'],
    ];

    for (var entry in entries) {
      rows.add([
        entry.getFormattedDate(),
        entry.getFormattedTime(),
        entry.entry,
        entry.secondLine ?? '',
      ]);
    }

    // Convert to CSV string
    String csv = const ListToCsvConverter().convert(rows);

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$filename.csv';
    final file = File(path);
    await file.writeAsString(csv);

    // Share the file
    await Share.shareXFiles([XFile(path)], text: 'InnerInk Journal Export');
  }

  // Export entries as Excel (XLSX)
  Future<void> exportAsExcel(List<JournalEntry> entries, String filename) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Journal'];

    // Add headers
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Time'),
      TextCellValue('Entry'),
      TextCellValue('Second Line'),
    ]);

    // Add data rows
    for (var entry in entries) {
      sheet.appendRow([
        TextCellValue(entry.getFormattedDate()),
        TextCellValue(entry.getFormattedTime()),
        TextCellValue(entry.entry),
        TextCellValue(entry.secondLine ?? ''),
      ]);
    }

    // Auto-fit columns (approximate)
    for (var i = 0; i < 4; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$filename.xlsx';
    final file = File(path);

    var fileBytes = excel.save();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);

      // Share the file
      await Share.shareXFiles([XFile(path)], text: 'InnerInk Journal Export');
    }
  }

  // Generate filename with timestamp
  String generateFilename(String prefix) {
    final now = DateTime.now();
    return '${prefix}_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }
}

