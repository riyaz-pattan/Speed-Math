/// Single source of truth for difficulty range boundaries across all topics.
///
/// Generators and tests read from this canonical specification.
abstract final class DifficultyRanges {
  DifficultyRanges._();

  // --- Addition ---
  // Easy: 2-digit + 2-digit (10..99 + 10..99)
  static const int additionEasyMin = 10;
  static const int additionEasyMax = 99;

  // Medium: 3-digit + 3-digit (100..999 + 100..999)
  static const int additionMediumMin = 100;
  static const int additionMediumMax = 999;

  // Hard: three numbers of 3 to 4 digits (100..9999 each)
  static const int additionHardMin = 100;
  static const int additionHardMax = 9999;
  static const int additionHardAddendCount = 3;

  // --- Subtraction ---
  // Easy: 2-digit - 2-digit (10..99 - 10..99, result >= 0)
  static const int subtractionEasyMin = 10;
  static const int subtractionEasyMax = 99;

  // Medium: 3-digit - 3-digit (100..999 - 100..999, result >= 0)
  static const int subtractionMediumMin = 100;
  static const int subtractionMediumMax = 999;

  // Hard: 4-digit - 4-digit (1000..9999 - 1000..9999, result >= 0)
  static const int subtractionHardMin = 1000;
  static const int subtractionHardMax = 9999;

  // --- Multiplication ---
  // Easy: 2-digit x 1-digit (10..99 x 2..9)
  static const int multiplicationEasyAMin = 10;
  static const int multiplicationEasyAMax = 99;
  static const int multiplicationEasyBMin = 2;
  static const int multiplicationEasyBMax = 9;

  // Medium: 2-digit x 2-digit (10..99 x 10..99)
  static const int multiplicationMediumMin = 10;
  static const int multiplicationMediumMax = 99;

  // Hard: 3-digit x 2-digit (100..999 x 10..99)
  static const int multiplicationHardAMin = 100;
  static const int multiplicationHardAMax = 999;
  static const int multiplicationHardBMin = 10;
  static const int multiplicationHardBMax = 99;

  // --- Division (always exact) ---
  // Easy: 2-digit / 1-digit (dividend 10..99, divisor 2..9)
  static const int divisionEasyDividendMin = 10;
  static const int divisionEasyDividendMax = 99;
  static const int divisionEasyDivisorMin = 2;
  static const int divisionEasyDivisorMax = 9;

  // Medium: 3-digit / 1-digit (quotient 30..150, divisor 3..9) OR 2-digit / 2-digit (divisor 11..25, quotient 3..9)
  static const int divisionMedium3by1QuotientMin = 30;
  static const int divisionMedium3by1QuotientMax = 150;
  static const int divisionMedium3by1DivisorMin = 3;
  static const int divisionMedium3by1DivisorMax = 9;
  static const int divisionMedium3by1DividendMin = 100;
  static const int divisionMedium3by1DividendMax = 999;

  static const int divisionMedium2by2DivisorMin = 11;
  static const int divisionMedium2by2DivisorMax = 25;
  static const int divisionMedium2by2QuotientMin = 3;
  static const int divisionMedium2by2QuotientMax = 9;
  static const int divisionMedium2by2DividendMin = 10;
  static const int divisionMedium2by2DividendMax = 99;

  // Hard: 4-digit / 2-digit (dividend 1000..9999, divisor 10..99)
  static const int divisionHardDividendMin = 1000;
  static const int divisionHardDividendMax = 9999;
  static const int divisionHardDivisorMin = 10;
  static const int divisionHardDivisorMax = 99;

  // --- Squares (n²) ---
  // Easy: 2 to 20
  static const int squaresEasyMin = 2;
  static const int squaresEasyMax = 20;

  // Medium: 21 to 50
  static const int squaresMediumMin = 21;
  static const int squaresMediumMax = 50;

  // Hard: 51 to 99 (no multiples of 10)
  static const int squaresHardMin = 51;
  static const int squaresHardMax = 99;

  // --- Cubes (n³) ---
  // Easy: 2 to 10
  static const int cubesEasyMin = 2;
  static const int cubesEasyMax = 10;

  // Medium: 11 to 20
  static const int cubesMediumMin = 11;
  static const int cubesMediumMax = 20;

  // Hard: 21 to 35 (no multiples of 10)
  static const int cubesHardMin = 21;
  static const int cubesHardMax = 35;

  // --- Square Roots (√n²) ---
  // Easy: root 2 to 20 (up to 20²)
  static const int squareRootsEasyMin = 2;
  static const int squareRootsEasyMax = 20;

  // Medium: root 21 to 50 (21² to 50²)
  static const int squareRootsMediumMin = 21;
  static const int squareRootsMediumMax = 50;

  // Hard: root 51 to 99 (51² to 99², no multiples of 10)
  static const int squareRootsHardMin = 51;
  static const int squareRootsHardMax = 99;

  // --- Cube Roots (∛n³) ---
  // Easy: root 2 to 10
  static const int cubeRootsEasyMin = 2;
  static const int cubeRootsEasyMax = 10;

  // Medium: root 11 to 20
  static const int cubeRootsMediumMin = 11;
  static const int cubeRootsMediumMax = 20;

  // Hard: root 21 to 35 (no multiples of 10)
  static const int cubeRootsHardMin = 21;
  static const int cubeRootsHardMax = 35;

  // --- Exponents (base^power) ---
  // Easy: base 2 to 9, power 2 to 3
  static const int exponentsEasyBaseMin = 2;
  static const int exponentsEasyBaseMax = 9;
  static const int exponentsEasyPowMin = 2;
  static const int exponentsEasyPowMax = 3;

  // Medium: base 2 to 9, power 2 to 5
  static const int exponentsMediumBaseMin = 2;
  static const int exponentsMediumBaseMax = 9;
  static const int exponentsMediumPowMin = 2;
  static const int exponentsMediumPowMax = 5;

  // Hard: base 2 to 15, power 3 to 6, result <= 1,000,000 (never base 1 or 10)
  static const int exponentsHardBaseMin = 2;
  static const int exponentsHardBaseMax = 15;
  static const int exponentsHardPowMin = 3;
  static const int exponentsHardPowMax = 6;
  static const int exponentsHardMaxResult = 1000000;

  // --- Percentages (x% of N) ---
  // Easy: x in [10, 20, 25, 50], N multiple of 20 up to 400
  static const List<int> percentagesEasyPercentages = [10, 20, 25, 50];
  static const int percentagesEasyNMultiple = 20;
  static const int percentagesEasyNMin = 20;
  static const int percentagesEasyNMax = 400;

  // Medium: x multiple of 5 (5..95), N multiple of 20 (100..1000)
  static const int percentagesMediumXMin = 5;
  static const int percentagesMediumXMax = 95;
  static const int percentagesMediumXMultiple = 5;
  static const int percentagesMediumNMin = 100;
  static const int percentagesMediumNMax = 1000;
  static const int percentagesMediumNMultiple = 20;

  // Hard: x% of A ± y% of B, x, y multiples of 5, A, B multiples of 20 (200..1500)
  static const int percentagesHardXMin = 5;
  static const int percentagesHardXMax = 95;
  static const int percentagesHardNMin = 200;
  static const int percentagesHardNMax = 1500;
  static const int percentagesHardNMultiple = 20;

  // --- Fractions (a/b of N) ---
  // Easy: b in [2, 3, 4, 5, 6, 8, 10], a < b, N multiple of b up to 200
  static const List<int> fractionsEasyDenominators = [2, 3, 4, 5, 6, 8, 10];
  static const int fractionsEasyNMax = 200;

  // Medium: b in 2..12, a < b, N multiple of b in 100..1000
  static const int fractionsMediumDenomMin = 2;
  static const int fractionsMediumDenomMax = 12;
  static const int fractionsMediumNMin = 100;
  static const int fractionsMediumNMax = 1000;

  // Hard: a/b of N ± c/d of M, b, d in 2..12, N, M in 100..600
  static const int fractionsHardDenomMin = 2;
  static const int fractionsHardDenomMax = 12;
  static const int fractionsHardNMin = 100;
  static const int fractionsHardNMax = 600;

  // --- Simplification (BODMAS) ---
  // Easy: small numbers, forms: a + b × c, a × b - c, a × b + c, a + b ÷ c
  static const int simplificationEasyMin = 2;
  static const int simplificationEasyMax = 12;
  static const int simplificationEasyAddendMax = 50;

  // Medium: numbers up to 50, result up to 5000, brackets and two operations
  static const int simplificationMediumOperandMax = 50;
  static const int simplificationMediumResultMax = 5000;

  // Hard: includes square and exact division, result up to 10000
  static const int simplificationHardSquareBaseMin = 12;
  static const int simplificationHardSquareBaseMax = 35;
  static const int simplificationHardResultMax = 10000;

  // --- Averages ---
  // Easy: 3 two-digit numbers (10..99), sum divisible by 3
  static const int averagesEasyCount = 3;
  static const int averagesEasyMin = 10;
  static const int averagesEasyMax = 99;

  // Medium: 5 numbers of 2 to 3 digits (20..300), sum divisible by 5
  static const int averagesMediumCount = 5;
  static const int averagesMediumMin = 20;
  static const int averagesMediumMax = 300;

  // Hard: Average of 5 numbers is A (20..150), 4 numbers given, find 5th
  static const int averagesHardCount = 5;
  static const int averagesHardAverageMin = 20;
  static const int averagesHardAverageMax = 150;

  // --- Missing Number ---
  // Easy: ? + a = b, 6 × ? = 48, etc. (numbers 2..99)
  static const int missingNumberEasyOperandMin = 2;
  static const int missingNumberEasyOperandMax = 99;

  // Medium: ? × 23 = 391, ? / 14 = 12, 205 - ? = 118 (numbers up to 500)
  static const int missingNumberMediumOperandMin = 4;
  static const int missingNumberMediumOperandMax = 500;

  // Hard: ? × 17 - 45 = 392, (? + 18) × 7 = 245
  static const int missingNumberHardOperandMin = 3;
  static const int missingNumberHardOperandMax = 500;
}
