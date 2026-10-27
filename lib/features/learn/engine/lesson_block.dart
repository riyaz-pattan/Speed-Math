// lib/features/learn/engine/lesson_block.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/enums/enums.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
abstract class LessonColors {
  static const Color tens = Color(0xFF2563EB);      // blue
  static const Color ones = Color(0xFFF97316);       // orange
  static const Color carry = Color(0xFFDC2626);      // red
  static const Color result = Color(0xFF16A34A);     // green
  static const Color arrowColor = Color(0xFF4F46E5); // indigo
  static const Color note = Color(0xFF78716C);       // warm gray
  static const Color heading = Color(0xFF1E293B);    // slate-800
  static const Color ink = Color(0xFF0F172A);        // near-black
}

// ─── Block Element types ──────────────────────────────────────────────────────

enum BElementType { text, underline, arrow, sideNote, highlight, circle }

/// Base element drawn on the whiteboard board.
class BElement {
  const BElement({
    required this.type,
    required this.x,
    required this.y,
    required this.startT,
    required this.endT,
    this.text,
    this.fontSize = 30,
    this.color = LessonColors.ink,
    this.fontFamily = '',
    this.fontWeight = FontWeight.normal,
    // Arrow / line fields
    this.x2,
    this.y2,
    this.label,
    this.labelColor,
    this.curved = false,
    this.strokeWidth = 2.0,
    // Highlight / circle
    this.width = 60,
    this.height = 36,
    // Anchor ID for arrows to reference
    this.anchorId,
  });

  final BElementType type;
  final double x, y;        // block-local coordinates (0,0 = top-left of block)
  final double startT, endT; // animation fraction within this block [0,1]
  final String? text;
  final double fontSize;
  final Color color;
  final String fontFamily;
  final FontWeight fontWeight;
  // Arrow
  final double? x2, y2;
  final String? label;
  final Color? labelColor;
  final bool curved;
  final double strokeWidth;
  // Highlight / circle
  final double width, height;
  // Anchor
  final String? anchorId;
}

// ─── Lesson Block ─────────────────────────────────────────────────────────────

/// One vertical block on the whiteboard = one step of the lesson.
class LessonBlock {
  const LessonBlock({
    required this.stepTitle,
    required this.caption,
    required this.blockHeight,
    required this.elements,
  });

  final String stepTitle;   // e.g. "Step 1", shown in Handwriting
  final String caption;     // plain text caption for accessibility
  final double blockHeight; // logical units (board is 360 wide)
  final List<BElement> elements;
}

// ─── Cross-block Arrow ────────────────────────────────────────────────────────

/// Arrow that spans two blocks (absolute board Y is resolved at paint time).
class CrossArrow {
  const CrossArrow({
    required this.fromBlock,
    required this.fromX,
    required this.fromLocalY,
    required this.toBlock,
    required this.toX,
    required this.toLocalY,
    required this.color,
    this.label,
    this.labelColor,
    this.curved = true,
    required this.animateOnBlock,
    required this.startT,
    required this.endT,
  });

  final int fromBlock;
  final double fromX, fromLocalY;
  final int toBlock;
  final double toX, toLocalY;
  final Color color;
  final String? label;
  final Color? labelColor;
  final bool curved;
  final int animateOnBlock;
  final double startT, endT;
}

// ─── Lesson Script ────────────────────────────────────────────────────────────

/// The complete script for one lesson (with given operands).
class LessonScript {
  const LessonScript({
    required this.problemText,
    required this.blocks,
    this.crossArrows = const [],
  });

  /// The problem shown in the sticky bar, e.g. "35² = ?"
  final String problemText;

  /// All blocks in order.
  final List<LessonBlock> blocks;

  /// Cross-block arrows spanning multiple blocks.
  final List<CrossArrow> crossArrows;
}

// ─── Lesson Variant ───────────────────────────────────────────────────────────

typedef LessonScriptBuilder = LessonScript Function(List<int> operands);

class LessonVariant {
  const LessonVariant({
    required this.variantId,
    required this.displayName,
    required this.builder,
    required this.featuredOperands,
    required this.generateOperands,
  });

  /// Unique ID within the lesson, e.g. "x25". Full progress ID = "lessonId:x25".
  final String variantId;
  final String displayName;  // e.g. "× 25"
  final LessonScriptBuilder builder;
  final List<int> featuredOperands;
  final List<int> Function(Random rng) generateOperands;
}

// ─── Lesson Meta ──────────────────────────────────────────────────────────────

class LessonMeta {
  const LessonMeta({
    required this.id,
    required this.title,
    required this.whyItWorks,
    required this.commonMistake,
    required this.category,
    required this.durationLabel,
    this.relatedTopic,
    this.variants = const [],
    // Single-variant fallback (used if variants is empty)
    LessonScriptBuilder? builder,
    List<int>? featuredOperands,
    List<int> Function(Random rng)? generateOperands,
    this.icon = Icons.lightbulb_outline_rounded,
    this.iconColor,
  })  : _builder = builder,
        _featuredOperands = featuredOperands,
        _generateOperands = generateOperands;

  final String id;
  final String title;
  final String whyItWorks;
  final String commonMistake;
  final String category;
  final String durationLabel;
  final Topic? relatedTopic;
  final List<LessonVariant> variants;
  final LessonScriptBuilder? _builder;
  final List<int>? _featuredOperands;
  final List<int> Function(Random rng)? _generateOperands;
  final IconData icon;
  final Color? iconColor;

  bool get hasVariants => variants.isNotEmpty;

  LessonVariant? variant(String variantId) {
    for (final v in variants) {
      if (v.variantId == variantId) return v;
    }
    return null;
  }

  /// Progress ID for this lesson (single-variant or specific variant).
  String progressId([String? variantId]) {
    if (variantId == null || variants.isEmpty) return id;
    return '$id:$variantId';
  }

  /// Build a script for single-variant lessons or safe fallback.
  LessonScript buildScript(List<int> operands) {
    final b = _builder;
    if (b != null) return b(operands);
    if (variants.isNotEmpty) {
      if (operands.length > 1) {
        final mult = operands[1];
        final v = variant('x$mult');
        if (v != null) return v.builder(operands);
      }
      return variants.first.builder(operands);
    }
    return LessonScript(
      problemText: operands.join(' × '),
      blocks: const [],
    );
  }

  List<int> get featuredOperands {
    final ops = _featuredOperands;
    if (ops != null && ops.isNotEmpty) {
      return ops;
    }
    if (variants.isNotEmpty) {
      return variants.first.featuredOperands;
    }
    return const [];
  }

  List<int> Function(Random) get generateOperands {
    final gen = _generateOperands;
    if (gen != null) return gen;
    if (variants.isNotEmpty) {
      return variants.first.generateOperands;
    }
    return (_) => const [];
  }
}
