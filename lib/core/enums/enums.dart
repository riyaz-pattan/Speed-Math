import '../strings/app_strings.dart';

/// Available math topics for practice.
enum Topic {
  addition(symbol: '+'),
  subtraction(symbol: '−'),
  multiplication(symbol: '×'),
  division(symbol: '÷'),
  squares(symbol: 'x²'),
  cubes(symbol: 'x³'),
  squareRoots(symbol: '√'),
  cubeRoots(symbol: '³√'),
  exponents(symbol: 'x^y'),
  mixed(symbol: '±');

  const Topic({required this.symbol});

  final String symbol;

  String get displayName => switch (this) {
    Topic.addition => AppStrings.addition,
    Topic.subtraction => AppStrings.subtraction,
    Topic.multiplication => AppStrings.multiplication,
    Topic.division => AppStrings.division,
    Topic.squares => AppStrings.squares,
    Topic.cubes => AppStrings.cubes,
    Topic.squareRoots => AppStrings.squareRoots,
    Topic.cubeRoots => AppStrings.cubeRoots,
    Topic.exponents => AppStrings.exponents,
    Topic.mixed => AppStrings.mixedTopics,
  };

  /// The 9 standard math drill topics (excludes mixed/smart topics).
  static List<Topic> get standardTopics =>
      values.where((t) => t != Topic.mixed).toList();
}

/// Difficulty levels with corresponding scoring multipliers.
enum Difficulty {
  easy(multiplier: 1.0),
  medium(multiplier: 1.5),
  hard(multiplier: 2.0),
  mixed(multiplier: 1.0);

  const Difficulty({required this.multiplier});

  final double multiplier;

  String get displayName => switch (this) {
    Difficulty.easy => AppStrings.easy,
    Difficulty.medium => AppStrings.medium,
    Difficulty.hard => AppStrings.hard,
    Difficulty.mixed => AppStrings.adaptive,
  };
}

/// Practice mode options: timed session vs fixed question count session.
enum PracticeMode {
  timer,
  questions,
  smart,
  mistakes;

  String get displayName => switch (this) {
    PracticeMode.timer => AppStrings.timerMode,
    PracticeMode.questions => AppStrings.questionMode,
    PracticeMode.smart => AppStrings.mixedPractice,
    PracticeMode.mistakes => AppStrings.mistakePractice,
  };
}

/// Keypad layout styles for numeric input during practice.
enum KeypadStyle {
  phone,
  calculator;

  String get displayName => switch (this) {
    KeypadStyle.phone => 'Phone dialer',
    KeypadStyle.calculator => 'Calculator',
  };
}

/// Kind of practice session.
enum SessionKind {
  drill,
  mixed,
  mistakes;

  String get displayName => switch (this) {
    SessionKind.drill => 'Drill',
    SessionKind.mixed => 'Mixed',
    SessionKind.mistakes => 'Mistakes',
  };
}

/// Vibration feedback intensity levels for haptics.
enum VibrationStrength {
  light('Light'),
  medium('Medium'),
  strong('Strong');

  final String displayName;
  const VibrationStrength(this.displayName);
}
