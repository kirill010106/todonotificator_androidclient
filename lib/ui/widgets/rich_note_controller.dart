import 'dart:convert';

import 'package:flutter/material.dart';

class RichNoteController extends TextEditingController {
  RichNoteController({String text = ''}) : super(text: text) {
    _previousText = text;
    addListener(_handleTextChanged);
  }

  final List<TextRange> _boldRanges = [];
  final List<TextRange> _italicRanges = [];
  final List<_LinkRange> _linkRanges = [];

  String _previousText = '';
  bool _isAdjusting = false;

  List<TextRange> get boldRanges => List.unmodifiable(_boldRanges);
  List<TextRange> get italicRanges => List.unmodifiable(_italicRanges);
  List<_LinkRange> get linkRanges => List.unmodifiable(_linkRanges);

  void loadFromStorage(String? raw) {
    final parsed = _decodeStorage(raw);
    _isAdjusting = true;
    _boldRanges
      ..clear()
      ..addAll(parsed.bold);
    _italicRanges
      ..clear()
      ..addAll(parsed.italic);
    _linkRanges
      ..clear()
      ..addAll(parsed.links);
    value = value.copyWith(
      text: parsed.text,
      selection: TextSelection.collapsed(offset: parsed.text.length),
      composing: TextRange.empty,
    );
    _previousText = parsed.text;
    _isAdjusting = false;
  }

  _LinkRange? _segmentLink(int start, int end) {
    for (final range in _linkRanges) {
      if (range.start <= start && range.end >= end) {
        return range;
      }
    }
    return null;
  }

  String toStorage() {
    final payload = <String, Object?>{
      'text': text,
      'bold': _boldRanges.map(_encodeRange).toList(),
      'italic': _italicRanges.map(_encodeRange).toList(),
      'links': _linkRanges.map((l) => [l.start, l.end, l.url]).toList(),
    };
    return jsonEncode(payload);
  }

  String toPlainText() => text;

  void toggleBold() => _toggleStyle(_boldRanges);

  void toggleItalic() => _toggleStyle(_italicRanges);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle();
    final textValue = value.text;
    if (textValue.isEmpty) {
      return TextSpan(text: '', style: baseStyle);
    }

    final boundaries = <int>{0, textValue.length};
    for (final range in _boldRanges) {
      boundaries.add(range.start);
      boundaries.add(range.end);
    }
    for (final range in _italicRanges) {
      boundaries.add(range.start);
      boundaries.add(range.end);
    }
    for (final link in _linkRanges) {
      boundaries.add(link.start);
      boundaries.add(link.end);
    }
    final sorted = boundaries.toList()..sort();

    final spans = <TextSpan>[];
    for (var i = 0; i < sorted.length - 1; i += 1) {
      final start = sorted[i];
      final end = sorted[i + 1];
      if (start == end) {
        continue;
      }
      final segment = textValue.substring(start, end);
      final isBold = _segmentStyled(_boldRanges, start, end);
      final isItalic = _segmentStyled(_italicRanges, start, end);
      final link = _segmentLink(start, end);
      var segmentStyle = baseStyle;
      if (isBold) {
        segmentStyle = segmentStyle.copyWith(fontWeight: FontWeight.w700);
      }
      if (isItalic) {
        segmentStyle = segmentStyle.copyWith(fontStyle: FontStyle.italic);
      }
      if (link != null) {
        segmentStyle = segmentStyle.copyWith(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        );
      }
      spans.add(TextSpan(text: segment, style: segmentStyle));
    }

    return TextSpan(style: baseStyle, children: spans);
  }

  void _toggleStyle(List<TextRange> ranges) {
    final selectionRange = selection;
    if (!selectionRange.isValid || selectionRange.isCollapsed) {
      return;
    }

    if (_selectionFullyStyled(ranges, selectionRange)) {
      _removeStyle(ranges, selectionRange);
    } else {
      _addStyle(ranges, selectionRange);
    }
    notifyListeners();
  }

  /// Add a link for the current selection. If selection is collapsed,
  /// insert the provided [url] as link text.
  void addLink(String url) {
    final selectionRange = selection;
    if (!selectionRange.isValid) return;

    if (selectionRange.isCollapsed) {
      final insertText = url;
      final start = selectionRange.start;
      final newText = text.replaceRange(start, start, insertText);
      final linkRange = TextRange(start: start, end: start + insertText.length);
      _isAdjusting = true;
      value = value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: linkRange.end),
      );
      _linkRanges.add(
        _LinkRange(start: linkRange.start, end: linkRange.end, url: url),
      );
      _normalizeLinks();
      _isAdjusting = false;
      notifyListeners();
      return;
    }

    // mark existing selection as link
    _linkRanges.add(
      _LinkRange(
        start: selectionRange.start,
        end: selectionRange.end,
        url: url,
      ),
    );
    _normalizeLinks();
    notifyListeners();
  }

  void _normalizeLinks() {
    _linkRanges.sort((a, b) => a.start.compareTo(b.start));
    final merged = <_LinkRange>[];
    for (final link in _linkRanges) {
      if (merged.isEmpty) {
        merged.add(link);
        continue;
      }
      final last = merged.last;
      if (link.start <= last.end) {
        // extend last to include link; prefer last.url
        merged[merged.length - 1] = _LinkRange(
          start: last.start,
          end: link.end > last.end ? link.end : last.end,
          url: last.url,
        );
      } else {
        merged.add(link);
      }
    }
    _linkRanges
      ..clear()
      ..addAll(merged);
  }

  void _addStyle(List<TextRange> ranges, TextRange selectionRange) {
    ranges.add(selectionRange);
    _normalizeRanges(ranges);
  }

  void _removeStyle(List<TextRange> ranges, TextRange selectionRange) {
    final next = <TextRange>[];
    for (final range in ranges) {
      if (selectionRange.end <= range.start ||
          selectionRange.start >= range.end) {
        next.add(range);
        continue;
      }
      if (selectionRange.start <= range.start &&
          selectionRange.end >= range.end) {
        continue;
      }
      if (selectionRange.start > range.start &&
          selectionRange.end < range.end) {
        next.add(TextRange(start: range.start, end: selectionRange.start));
        next.add(TextRange(start: selectionRange.end, end: range.end));
        continue;
      }
      if (selectionRange.start <= range.start) {
        next.add(TextRange(start: selectionRange.end, end: range.end));
        continue;
      }
      if (selectionRange.end >= range.end) {
        next.add(TextRange(start: range.start, end: selectionRange.start));
      }
    }
    ranges
      ..clear()
      ..addAll(next);
  }

  bool _selectionFullyStyled(List<TextRange> ranges, TextRange selectionRange) {
    for (final range in ranges) {
      if (range.start <= selectionRange.start &&
          range.end >= selectionRange.end) {
        return true;
      }
    }
    return false;
  }

  void _normalizeRanges(List<TextRange> ranges) {
    ranges.sort((a, b) => a.start.compareTo(b.start));
    final merged = <TextRange>[];
    for (final range in ranges) {
      if (merged.isEmpty) {
        merged.add(range);
        continue;
      }
      final last = merged.last;
      if (range.start <= last.end) {
        merged[merged.length - 1] = TextRange(
          start: last.start,
          end: range.end > last.end ? range.end : last.end,
        );
      } else {
        merged.add(range);
      }
    }
    ranges
      ..clear()
      ..addAll(merged);
  }

  void _handleTextChanged() {
    if (_isAdjusting) {
      return;
    }
    final newText = text;
    final oldText = _previousText;
    if (newText == oldText) {
      return;
    }

    final diff = _diff(oldText, newText);
    _shiftRanges(_boldRanges, diff);
    _shiftRanges(_italicRanges, diff);
    _shiftLinkRanges(diff);
    _previousText = newText;
  }

  void _shiftLinkRanges(_TextDiff diff) {
    if (diff.delta == 0 && diff.oldLength == 0) return;
    final updated = <_LinkRange>[];
    for (final link in _linkRanges) {
      if (link.end <= diff.start) {
        updated.add(link);
        continue;
      }
      if (link.start >= diff.endOld) {
        updated.add(
          _LinkRange(
            start: link.start + diff.delta,
            end: link.end + diff.delta,
            url: link.url,
          ),
        );
        continue;
      }

      final isInsertion = diff.oldLength == 0 && diff.newLength > 0;
      final isDeletion = diff.newLength == 0 && diff.oldLength > 0;

      if (isInsertion && diff.start >= link.start && diff.start <= link.end) {
        updated.add(
          _LinkRange(
            start: link.start,
            end: link.end + diff.delta,
            url: link.url,
          ),
        );
        continue;
      }

      if (isDeletion && diff.start >= link.start && diff.start < link.end) {
        final newEnd = link.end + diff.delta;
        if (newEnd > link.start) {
          updated.add(
            _LinkRange(start: link.start, end: newEnd, url: link.url),
          );
        }
        continue;
      }
    }
    _linkRanges
      ..clear()
      ..addAll(updated);
  }

  void _shiftRanges(List<TextRange> ranges, _TextDiff diff) {
    if (diff.delta == 0 && diff.oldLength == 0) {
      return;
    }
    final updated = <TextRange>[];
    for (final range in ranges) {
      if (range.end <= diff.start) {
        updated.add(range);
        continue;
      }
      if (range.start >= diff.endOld) {
        updated.add(
          TextRange(
            start: range.start + diff.delta,
            end: range.end + diff.delta,
          ),
        );
        continue;
      }

      final isInsertion = diff.oldLength == 0 && diff.newLength > 0;
      final isDeletion = diff.newLength == 0 && diff.oldLength > 0;

      if (isInsertion && diff.start >= range.start && diff.start <= range.end) {
        updated.add(TextRange(start: range.start, end: range.end + diff.delta));
        continue;
      }

      if (isDeletion && diff.start >= range.start && diff.start < range.end) {
        final newEnd = range.end + diff.delta;
        if (newEnd > range.start) {
          updated.add(TextRange(start: range.start, end: newEnd));
        }
        continue;
      }
    }
    ranges
      ..clear()
      ..addAll(updated);
  }

  _TextDiff _diff(String oldText, String newText) {
    var prefix = 0;
    final minLength = oldText.length < newText.length
        ? oldText.length
        : newText.length;
    while (prefix < minLength &&
        oldText.codeUnitAt(prefix) == newText.codeUnitAt(prefix)) {
      prefix += 1;
    }

    var suffix = 0;
    while (suffix < minLength - prefix &&
        oldText.codeUnitAt(oldText.length - 1 - suffix) ==
            newText.codeUnitAt(newText.length - 1 - suffix)) {
      suffix += 1;
    }

    final oldLength = oldText.length - prefix - suffix;
    final newLength = newText.length - prefix - suffix;

    return _TextDiff(
      start: prefix,
      endOld: prefix + oldLength,
      oldLength: oldLength,
      newLength: newLength,
    );
  }

  bool _segmentStyled(List<TextRange> ranges, int start, int end) {
    for (final range in ranges) {
      if (range.start <= start && range.end >= end) {
        return true;
      }
    }
    return false;
  }

  _RichNotePayload _decodeStorage(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const _RichNotePayload(text: '', bold: [], italic: [], links: []);
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic> && decoded['text'] is String) {
        return _RichNotePayload(
          text: decoded['text'] as String,
          bold: _decodeRanges(decoded['bold']),
          italic: _decodeRanges(decoded['italic']),
          links: _decodeLinks(decoded['links']),
        );
      }
    } catch (_) {
      // Fall back to raw text.
    }
    return _RichNotePayload(
      text: raw,
      bold: const [],
      italic: const [],
      links: const [],
    );
  }

  List<TextRange> _decodeRanges(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    return raw
        .whereType<List>()
        .where((pair) => pair.length == 2)
        .map(
          (pair) => TextRange(
            start: (pair[0] as num).toInt(),
            end: (pair[1] as num).toInt(),
          ),
        )
        .toList();
  }

  List<_LinkRange> _decodeLinks(Object? raw) {
    if (raw is! List) return const [];
    final out = <_LinkRange>[];
    for (final item in raw) {
      if (item is List && item.length == 3) {
        final s = (item[0] as num).toInt();
        final e = (item[1] as num).toInt();
        final url = item[2]?.toString() ?? '';
        out.add(_LinkRange(start: s, end: e, url: url));
      }
    }
    return out;
  }

  List<int> _encodeRange(TextRange range) {
    return [range.start, range.end];
  }
}

class _RichNotePayload {
  const _RichNotePayload({
    required this.text,
    required this.bold,
    required this.italic,
    required this.links,
  });

  final String text;
  final List<TextRange> bold;
  final List<TextRange> italic;
  final List<_LinkRange> links;
}

class _TextDiff {
  const _TextDiff({
    required this.start,
    required this.endOld,
    required this.oldLength,
    required this.newLength,
  });

  final int start;
  final int endOld;
  final int oldLength;
  final int newLength;

  int get delta => newLength - oldLength;
}

class _LinkRange {
  const _LinkRange({required this.start, required this.end, required this.url});

  final int start;
  final int end;
  final String url;
}
