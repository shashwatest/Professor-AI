// lib/services/_export_service_web.dart
// Web implementation: uses browser Blob + anchor download (no dart:io)

import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import 'package:ai_classroom_assistant/services/_export_service_shared.dart';

String _sanitizeFileNameForWeb(String name) => sanitizeFileName(name);

Future<void> exportAsText(String content, String filename) async {
  try {
    final safeName = _sanitizeFileNameForWeb(filename);
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], 'text/plain;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement;
    anchor.href = url;
    anchor.style.display = 'none';
    anchor.download = '$safeName.txt';
    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  } catch (e) {
    throw Exception('Failed to export text (web): $e');
  }
}

Future<void> exportAsPDF(String content, String filename) async {
  try {
    final pdf = pw.Document();

    final theme = pw.ThemeData();
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

    final bytes = await pdf.save(); // Uint8List
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement;
    anchor.href = url;
    anchor.style.display = 'none';
    final safeName = _sanitizeFileNameForWeb(filename);
    anchor.download = '$safeName.pdf';
    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  } catch (e) {
    throw Exception('Failed to export PDF (web): $e');
  }
}
