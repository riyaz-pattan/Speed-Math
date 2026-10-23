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
  percentages(symbol: '%'),
  fractions(symbol: '½'),
  simplification(symbol: '( )'),
  averages(symbol: 'x̄'),
  missingNumber(symbol: '?'),
  numberSeries(symbol: '...'),
  approximation(symbol: '≈'),
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
    Topic.percentages => AppStrings.percentages,
    Topic.fractions => AppStrings.fractions,
    Topic.simplification => AppStrings.simplification,
    Topic.averages => AppStrings.averages,
    Topic.missingNumber => AppStrings.missingNumber,
    Topic.numberSeries => AppStrings.numberSeries,
    Topic.approximation => AppStrings.approximation,
    Topic.mixed => AppStrings.mixedTopics,
  };

  /// The standard math drill topics (excludes mixed/smart topics).
  static List<Topic> get standardTopics =>
      values.where((t) => t != Topic.mixed).toList();
}

/// The three broad groups organizing practice topics across Home and Practice screens.
enum TopicGroup {
  arithmetic,
  powersAndRoots,
  appliedMaths;

  String get displayName => switch (this) {
    TopicGroup.arithmetic => 'Arithmetic',
    TopicGroup.powersAndRoots => 'Powers & Roots',
    TopicGroup.appliedMaths => 'Applied Maths',
  };

  List<Topic> get topics => switch (this) {
    TopicGroup.arithmetic => const [
      Topic.addition,
      Topic.subtraction,
      Topic.multiplication,
      Topic.division,
    ],
    TopicGroup.powersAndRoots => const [
      Topic.squares,
      Topic.cubes,
      Topic.squareRoots,
      Topic.cubeRoots,
      Topic.exponents,
    ],
    TopicGroup.appliedMaths => const [
      Topic.percentages,
      Topic.fractions,
      Topic.simplification,
      Topic.approximation,
      Topic.averages,
      Topic.missingNumber,
      Topic.numberSeries,
    ],
  };
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
