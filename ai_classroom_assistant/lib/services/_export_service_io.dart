// lib/services/_export_service_io.dart
// Non-web implementation: uses path_provider + dart:io + share_plus + pdf

import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import 'package:ai_classroom_assistant/services/_export_service_shared.dart';

Future<void> exportAsText(String content, String filename) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final safeName = sanitizeFileName(filename);
    final file = File('${dir.path}/$safeName.txt');
    await file.writeAsString(content);

    final xfile = XFile(file.path);
    await Share.shareXFiles([xfile], subject: filename);
  } catch (e) {
    throw Exception('Failed to export text: $e');
  }
}

Future<void> exportAsPDF(String content, String filename) async {
  try {
    final pdf = pw.Document();

    // Optionally prepare a theme (fonts). Leave default fonts if embedding is not required.
    final theme = pw.ThemeData();

    // Build body widgets using shared helper
    final bodyWidgets = buildPdfWidgetsFromContent(content, theme: theme);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return <pw.Widget>[
            pw.Text(filename, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            ...bodyWidgets,
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final safeName = sanitizeFileName(filename);
    final file = File('${dir.path}/$safeName.pdf');
    await file.writeAsBytes(bytes);

    final xfile = XFile(file.path);
    await Share.shareXFiles([xfile], subject: filename);
  } catch (e) {
    throw Exception('Failed to export PDF: $e');
  }
}
