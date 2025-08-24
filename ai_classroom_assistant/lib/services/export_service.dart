import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportService {
  static Future<void> exportAsText(String content, String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename.txt');
      await file.writeAsString(content);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: filename,
      );
    } catch (e) {
      throw Exception('Failed to export text: $e');
    }
  }

  static Future<void> exportAsPDF(String content, String title) async {
    try {
      final pdf = pw.Document();
      
      // Split content into chunks to avoid page overflow
      final lines = content.split('\n');
      final chunks = <String>[];
      String currentChunk = '';
      
      for (final line in lines) {
        if (currentChunk.length + line.length > 2000) {
          chunks.add(currentChunk);
          currentChunk = line;
        } else {
          currentChunk += (currentChunk.isEmpty ? '' : '\n') + line;
        }
      }
      if (currentChunk.isNotEmpty) chunks.add(currentChunk);
      
      for (int i = 0; i < chunks.length; i++) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (i == 0) ...
                  [
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                  ],
                  pw.Expanded(
                    child: pw.Text(
                      chunks[i],
                      style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.4),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$title.pdf');
      await file.writeAsBytes(await pdf.save());
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: title,
      );
    } catch (e) {
      throw Exception('Failed to export PDF: $e');
    }
  }
}