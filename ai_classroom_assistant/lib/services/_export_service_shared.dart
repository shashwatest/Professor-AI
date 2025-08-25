// lib/services/_export_service_shared.dart
// Shared helpers used by both IO and Web implementations.
// Converts markdown-like text into a list of pdf package widgets.
// No dart:io or dart:html imports here.

import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

/// Public API: build PDF body widgets from markdown-like content.
/// `theme` is optional (can be used to set fonts). If null, defaults are used.
List<pw.Widget> buildPdfWidgetsFromContent(String content, {pw.ThemeData? theme}) {
  final widgets = <pw.Widget>[];
  // Normalize newlines
  content = content.replaceAll('\r\n', '\n');

  // Protect fenced code blocks: split by fenced blocks so we don't process inline math there
  final fencedRegex = RegExp(r'```(.|\n)*?```', dotAll: true);
  final parts = <_Segment>[];
  int last = 0;
  for (final m in fencedRegex.allMatches(content)) {
    if (m.start > last) {
      parts.add(_Segment(content.substring(last, m.start), isCode: false));
    }
    parts.add(_Segment(content.substring(m.start, m.end), isCode: true));
    last = m.end;
  }
  if (last < content.length) {
    parts.add(_Segment(content.substring(last), isCode: false));
  }

  for (final part in parts) {
    if (part.isCode) {
      // remove the triple backticks and optional language
      final code = part.text.replaceFirst(RegExp(r'^```[^\n]*\n?'), '').replaceFirst(RegExp(r'\n?```$'), '');
      widgets.add(
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          margin: const pw.EdgeInsets.symmetric(vertical: 6),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(code, style: const pw.TextStyle(fontSize: 10)),
        ),
      );
      continue;
    }

    // For non-code parts, split by block math $$...$$
    final blockMathRegex = RegExp(r'\$\$(.+?)\$\$', dotAll: true);
    int lastB = 0;
    for (final bm in blockMathRegex.allMatches(part.text)) {
      if (bm.start > lastB) {
        final before = part.text.substring(lastB, bm.start);
        widgets.addAll(_renderTextChunkAsPdf(before, theme));
      }
      final formula = bm.group(1) ?? '';
      widgets.add(
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          margin: const pw.EdgeInsets.symmetric(vertical: 6),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(r'$$' + formula.trim() + r'$$', style: const pw.TextStyle(fontSize: 11)),
        ),
      );
      lastB = bm.end;
    }
    if (lastB < part.text.length) {
      final tail = part.text.substring(lastB);
      widgets.addAll(_renderTextChunkAsPdf(tail, theme));
    }
  }

  return widgets;
}

/// Convert a textual chunk (no code-fence, no block-math) to PDF widgets by
/// splitting into headings, lists, paragraphs and handling inline tokens.
List<pw.Widget> _renderTextChunkAsPdf(String textChunk, pw.ThemeData? theme) {
  final out = <pw.Widget>[];
  if (textChunk.trim().isEmpty) return out;

  final lines = textChunk.split('\n');
  final buffer = <String>[];

  void flushBuffer() {
    if (buffer.isEmpty) return;
    final paragraph = buffer.join('\n').trim();
    if (paragraph.isNotEmpty) out.add(_buildParagraphPdf(paragraph, theme));
    buffer.clear();
  }

  for (final raw in lines) {
    final line = raw.trimLeft();
    if (line.startsWith('#') ||
        line.startsWith('- ') ||
        line.startsWith('* ') ||
        RegExp(r'^\d+\.\s').hasMatch(line) ||
        line.startsWith('> ')) {
      flushBuffer();
      out.add(_buildParagraphPdf(line, theme));
    } else if (line.isEmpty) {
      flushBuffer();
    } else {
      buffer.add(raw);
    }
  }

  flushBuffer();
  return out;
}

/// Build a single paragraph/list/heading PDF widget from a line of text.
pw.Widget _buildParagraphPdf(String line, pw.ThemeData? theme) {
  final t = line.trim();

  // Heading
  final headingMatch = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(t);
  if (headingMatch != null) {
    final level = headingMatch.group(1)!.length;
    final content = headingMatch.group(2)!;
    final size = (20 - (level - 1) * 2).clamp(12, 22).toDouble();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10, bottom: 6),
      child: pw.Text(content, style: pw.TextStyle(fontSize: size, fontWeight: pw.FontWeight.bold)),
    );
  }

  // List item
  final bulletMatch = RegExp(r'^(-|\*|\u2022|\d+\.)\s+(.*)$').firstMatch(t);
  if (bulletMatch != null) {
    final bullet = bulletMatch.group(1)!;
    final rest = bulletMatch.group(2)!;
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Container(width: 18, child: pw.Text(bullet.endsWith('.') ? bullet : '•', style: const pw.TextStyle(fontSize: 12))),
        pw.Expanded(child: _buildRichTextPdf(rest)),
      ]),
    );
  }

  // Blockquote
  if (t.startsWith('> ')) {
    final inner = t.substring(2).trim();
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: _buildRichTextPdf(inner),
    );
  }

  // Plain paragraph
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: _buildRichTextPdf(t),
  );
}

/// Build pw.RichText from a line, handling inline tokens:
/// - inline math $...$ -> shown as monospace ` $...$ `
/// - **bold** -> bold
/// - _italic_ -> italic
/// - `code` -> monospace
pw.Widget _buildRichTextPdf(String source) {
  // Protect escaped dollar signs
  final escapedDollarPlaceholder = '\uE001';
  source = source.replaceAll(r'\$', escapedDollarPlaceholder);

  final spans = <pw.TextSpan>[];
  int index = 0;
  final length = source.length;

  while (index < length) {
    // find next occurrence of any token after index
    final substring = source.substring(index);

    final mathMatch = RegExp(r'(?<!\$)\$(?!\$)(.+?)(?<!\$)\$(?!\$)', dotAll: true).firstMatch(substring);
    final boldMatch = RegExp(r'\*\*(.+?)\*\*', dotAll: true).firstMatch(substring);
    final italicMatch = RegExp(r'_(.+?)_', dotAll: true).firstMatch(substring);
    final codeMatch = RegExp(r'`([^`]+?)`', dotAll: true).firstMatch(substring);

    final matches = <_TokenMatch>[];
    if (mathMatch != null) matches.add(_TokenMatch('math', index + mathMatch.start, index + mathMatch.end, mathMatch.group(1)!));
    if (boldMatch != null) matches.add(_TokenMatch('bold', index + boldMatch.start, index + boldMatch.end, boldMatch.group(1)!));
    if (italicMatch != null) matches.add(_TokenMatch('italic', index + italicMatch.start, index + italicMatch.end, italicMatch.group(1)!));
    if (codeMatch != null) matches.add(_TokenMatch('code', index + codeMatch.start, index + codeMatch.end, codeMatch.group(1)!));

    if (matches.isEmpty) {
      final remaining = source.substring(index).replaceAll(escapedDollarPlaceholder, r'$');
      spans.add(pw.TextSpan(text: remaining));
      break;
    }

    matches.sort((a, b) => a.start.compareTo(b.start));
    final token = matches.first;

    if (token.start > index) {
      final plain = source.substring(index, token.start).replaceAll(escapedDollarPlaceholder, r'$');
      spans.add(pw.TextSpan(text: plain));
    }

    if (token.type == 'math') {
      // render inline math as monospace text including delimiters for clarity
      spans.add(pw.TextSpan(text: r' $' + token.content + r'$ ', style: const pw.TextStyle(fontSize: 11)));
    } else if (token.type == 'bold') {
      spans.add(pw.TextSpan(text: token.content, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
    } else if (token.type == 'italic') {
      spans.add(pw.TextSpan(text: token.content, style: pw.TextStyle(fontStyle: pw.FontStyle.italic)));
    } else if (token.type == 'code') {
      spans.add(pw.TextSpan(text: token.content, style: const pw.TextStyle(fontSize: 11)));
    }

    index = token.end;
  }

  return pw.RichText(text: pw.TextSpan(children: spans, style: const pw.TextStyle(fontSize: 11)));
}

/// sanitize filename
String sanitizeFileName(String name) {
  return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
}

/// small helpers
class _Segment {
  final String text;
  final bool isCode;
  _Segment(this.text, {this.isCode = false});
}

class _TokenMatch {
  final String type;
  final int start;
  final int end;
  final String content;
  _TokenMatch(this.type, this.start, this.end, this.content);
}
