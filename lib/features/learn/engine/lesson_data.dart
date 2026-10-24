// lib/features/learn/engine/lesson_data.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/enums/enums.dart';

// ─── Draw Element ─────────────────────────────────────────────────────────────

enum DrawElementType {
  writtenText, // text that wipes left→right
  arrow, // path trim
  underline, // growing horizontal line
  highlight, // fade-in rounded rect
  fractionBar, // growing horizontal line (semantic alias)
  staticText, // appears instantly
}

/// A single visual element on the lesson whiteboard.
class DrawElement {
  const DrawElement({
    required this.type,
    required this.x,
    required this.y,
    required this.startT,
    required this.endT,
    this.text,
    this.fontSize = 28,
    this.color = const Color(0xFF0F172A),
    this.fontFamily = 'Handwriting',
    this.fontWeight = FontWeight.normal,
    this.arrowEnd,
    this.lineWidth = 120,
    this.lineHeight = 3,
    this.highlightWidth = 80,
    this.highlightHeight = 32,
  });

  final DrawElementType type;
  final double x;
  final double y;
  final double startT;
  final double endT;
  final String? text;
  final double fontSize;
  final Color color;
  final String fontFamily;
  final FontWeight fontWeight;
  final Offset? arrowEnd;
  final double lineWidth;
  final double lineHeight;
  final double highlightWidth;
  final double highlightHeight;
}

// ─── Lesson Step ──────────────────────────────────────────────────────────────

class LessonStep {
  const LessonStep({
    required this.elements,
    required this.caption,
  });

  final List<DrawElement> elements;
  final String caption;
}

// ─── Lesson Meta ──────────────────────────────────────────────────────────────

typedef LessonStepsBuilder = List<LessonStep> Function(List<int> operands);

class LessonMeta {
  const LessonMeta({
    required this.id,
    required this.title,
    required this.whyItWorks,
    required this.commonMistake,
    required this.category,
    required this.durationLabel,
    this.relatedTopic,
    required this.featuredBuilder,
    required this.featuredOperands,
    required this.generateOperands,
    this.icon = Icons.lightbulb_outline_rounded,
  });

  final String id;
  final String title;
  final String whyItWorks;
  final String commonMistake;
  final String category;
  final String durationLabel;
  final Topic? relatedTopic;
  final LessonStepsBuilder featuredBuilder;
  final List<int> featuredOperands;
  final List<int> Function(Random rng) generateOperands;
  final IconData icon;
}
