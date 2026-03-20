import 'package:flutter/material.dart';

/// Highlights matching text within a string with a specified color
class HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? style;
  final Color highlightColor;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool applyTextScaler;

  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    this.style,
    required this.highlightColor,
    this.maxLines,
    this.overflow,
    this.applyTextScaler = false,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final List<TextSpan> spans = _buildHighlightedSpans(text, query);
    
    return RichText(
      text: TextSpan(children: spans, style: style),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      textScaler: applyTextScaler ? MediaQuery.textScalerOf(context) : TextScaler.noScaling,
    );
  }

  List<TextSpan> _buildHighlightedSpans(String text, String query) {
    final List<TextSpan> spans = [];
    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();
    
    int currentIndex = 0;
    
    while (currentIndex < text.length) {
      final int matchIndex = lowerText.indexOf(lowerQuery, currentIndex);
      
      if (matchIndex == -1) {
        // No more matches, add the rest of the text
        spans.add(TextSpan(text: text.substring(currentIndex)));
        break;
      }
      
      // Add text before match
      if (matchIndex > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, matchIndex)));
      }
      
      // Add highlighted match - only set background, inherit everything else
      spans.add(
        TextSpan(
          text: text.substring(matchIndex, matchIndex + query.length),
          style: TextStyle(
            inherit: true,
            backgroundColor: highlightColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      
      currentIndex = matchIndex + query.length;
    }
    
    return spans;
  }
}
