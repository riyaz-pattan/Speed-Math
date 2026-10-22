import 'coach_constants.dart';

/// Pure Dart utility to clean, sanitize, and normalize raw user queries
/// and map domain shorthand, typos, and synonyms to canonical tokens.
abstract final class TextNormalizer {
  TextNormalizer._();

  static const Map<String, String> _wordReplacements = {
    // Operations & topics
    'mul': 'multiplication',
    'mult': 'multiplication',
    'multiply': 'multiplication',
    'multiplicatin': 'multiplication',
    'times': 'multiplication',
    'div': 'division',
    'divide': 'division',
    'divison': 'division',
    'divsn': 'division',
    'sub': 'subtraction',
    'minus': 'subtraction',
    'subtract': 'subtraction',
    'substraction': 'subtraction',
    'add': 'addition',
    'plus': 'addition',
    'sum': 'addition',
    'sq': 'squares',
    'square': 'squares',
    'cbrt': 'cube roots',
    'cb root': 'cube roots',
    'cube root': 'cube roots',
    'cube roots': 'cube roots',
    'sqrt': 'square roots',
    'sq root': 'square roots',
    'square root': 'square roots',
    'square roots': 'square roots',
    'cube': 'cubes',
    'power': 'exponents',
    'powers': 'exponents',
    'exponent': 'exponents',
    'index': 'exponents',
    'indices': 'exponents',

    // Common query typos & abbreviations
    'wher': 'where',
    'whr': 'where',
    'wek': 'weak',
    'weka': 'weak',
    'hw': 'how',
    'wht': 'what',
    'wat': 'what',
    'shud': 'should',
    'shld': 'should',
    'pln': 'plan',
    'prctice': 'practice',
    'practise': 'practice',
    'imprv': 'improving',
    'improvingg': 'improving',
    'thx': 'thanks',
    'roots': 'square roots',
    'root': 'square roots',
    'tday': 'today',
    'qs': 'questions',
    'q': 'questions',
    'mins': 'minutes',
    'min': 'minutes',
    'sec': 'seconds',
    'secs': 'seconds',
    'diff': 'difference',
    'avg': 'average',
    'acc': 'accuracy',
    'mistaks': 'mistakes',
    'fastr': 'faster',
    'gettin': 'getting',
    'giv': 'give',
    'som': 'some',
    'advic': 'advice',
    'hlp': 'help',
    'pls': 'please',
    'acurate': 'accurate',
  };

  /// Normalizes [input]:
  /// 1. Trims length to [CoachConstants.maxInputLength].
  /// 2. Converts to lowercase.
  /// 3. Removes punctuation except letters and numbers.
  /// 4. Replaces multi-word phrases (e.g. 'square root', 'cube root').
  /// 5. Maps word-level synonyms and shorthand.
  /// 6. Collapses contiguous whitespace.
  static String normalize(String input) {
    if (input.isEmpty) return '';

    var text = input.trim();
    if (text.length > CoachConstants.maxInputLength) {
      text = text.substring(0, CoachConstants.maxInputLength);
    }

    text = text.toLowerCase();

    // Replace multi-word math phrases before splitting
    text = text.replaceAll('square root', 'square roots');
    text = text.replaceAll('sq root', 'square roots');
    text = text.replaceAll('cube root', 'cube roots');
    text = text.replaceAll('cb root', 'cube roots');

    // Remove punctuation keeping only letters, digits, and spaces
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final code = char.codeUnitAt(0);
      final isAlpha = (code >= 97 && code <= 122); // a-z
      final isDigit = (code >= 48 && code <= 57); // 0-9
      final isSpace = (code == 32 || code == 9 || code == 10); // space, tab, newline

      if (isAlpha || isDigit) {
        buffer.write(char);
      } else if (isSpace) {
        buffer.write(' ');
      } else {
        buffer.write(' ');
      }
    }

    final cleaned = buffer.toString();
    final rawTokens = cleaned.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);

    final mappedTokens = rawTokens.map((token) {
      return _wordReplacements[token] ?? token;
    });

    return mappedTokens.join(' ').trim();
  }
}
