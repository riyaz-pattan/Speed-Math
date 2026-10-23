/// Centralized collection of all user-facing strings in the app.
///
/// All user-facing text goes here so other languages can be added later.
abstract final class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'Speed Math with AI';
  static const String appTitle = 'Speed Math with AI';
  static const String appTagline = 'Master mental math with speed and precision';

  // Navigation Tabs
  static const String tabHome = 'Home';
  static const String tabPractice = 'Practice';
  static const String tabStats = 'Stats';
  static const String tabReport = 'Report';
  static const String tabSettings = 'Settings';

  // Aliases for navigation (used in shell)
  static const String home = 'Home';
  static const String practice = 'Practice';
  static const String stats = 'Stats';
  static const String report = 'Report';
  static const String settings = 'Settings';

  // Common Actions & Labels
  static const String start = 'Start';
  static const String pause = 'Pause';
  static const String resume = 'Resume';
  static const String quit = 'Quit';
  static const String submit = 'Submit';
  static const String skip = 'Skip';
  static const String playAgain = 'Play Again';
  static const String changeSetup = 'Change Setup';
  static const String backToHome = 'Back to Home';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String continueText = 'Continue';
  static const String retry = 'Retry';
  static const String clear = 'Clear';
  static const String back = 'Back';
  static const String close = 'Close';
  static const String done = 'Done';
  static const String next = 'Next';

  // Difficulty
  static const String easy = 'Easy';
  static const String medium = 'Medium';
  static const String hard = 'Hard';
  static const String difficulty = 'Difficulty';

  // Topics
  static const String addition = 'Addition';
  static const String subtraction = 'Subtraction';
  static const String multiplication = 'Multiplication';
  static const String division = 'Division';
  static const String squares = 'Squares';
  static const String cubes = 'Cubes';
  static const String squareRoots = 'Square Roots';
  static const String cubeRoots = 'Cube Roots';
  static const String exponents = 'Exponents';
  static const String percentages = 'Percentages';
  static const String fractions = 'Fractions';
  static const String simplification = 'Simplification';
  static const String averages = 'Averages';
  static const String missingNumber = 'Missing Number';
  static const String topic = 'Topic';

  // Practice Modes & Setup
  static const String timerMode = 'Timer Mode';
  static const String questionMode = 'Question Mode';
  static const String smartPractice = 'Smart Practice';
  static const String mixedPractice = 'Mixed practice';
  static const String mistakePractice = 'Mistakes practice';
  static const String practiceYourMistakes = 'Practice your mistakes';
  static const String practiceMyMistakes = 'Practice my mistakes';
  static const String myMistakes = 'My mistakes';
  static const String mistakes = 'Mistakes';
  static const String mixedTopics = 'Mixed Topics';
  static const String adaptive = 'Adaptive';
  static const String auto = 'Auto';
  static const String autoDifficultyExplanation =
      'The app picks questions from your level and weak areas.';
  static const String focusWeakAreas = 'Focus on my weak areas';
  static const String focusWeakAreasExplanation =
      'More questions from the types you find hardest. Never goes beyond the difficulty you chose.';
  static const String yourWeakSpots = 'Your weak spots';
  static const String seeAll = 'See all';
  static const String practiceThese = 'Practice these';
  static const String mistakesToRevise = 'mistakes to revise';
  static const String noMistakesToRevise = 'No mistakes to revise! Keep practicing.';
  static const String allTopics = 'All topics';
  static const String noMistakesInBank = 'No mistakes to revise!';
  static const String noMistakesInBankSubtitle =
      'You are all caught up. Keep practicing to build speed.';
  static const String timer = 'Timer';
  static const String questions = 'Questions';
  static const String mode = 'Mode';
  static const String selectDuration = 'Select Duration';
  static const String selectQuestionCount = 'Number of Questions';
  static const String secondsSuffix = 's';
  static const String questionsSuffix = 'Q';

  // Settings
  static const String theme = 'Theme';
  static const String sound = 'Sound';
  static const String soundDescription = 'Sound effects for answers and timer';
  static const String correctSound = 'Correct answer sound';
  static const String correctSoundDescription = 'Play a chime on correct answers';
  static const String wrongSound = 'Wrong answer & skip sound';
  static const String wrongSoundDescription = 'Play a tone on wrong tries and skips';
  static const String soundVolume = 'Sound volume';
  static const String correctSoundVolume = 'Correct answer volume';
  static const String wrongSoundVolume = 'Wrong & skip volume';
  static const String haptics = 'Haptics';
  static const String hapticsDescription =
      'Vibrate on key presses, answers and results';
  static const String autoSubmit = 'Auto-submit';
  static const String autoSubmitDescription =
      'Instant advance on correct answer, or auto-submit on full length';
  static const String autoAdvance = autoSubmit;
  static const String autoAdvanceDescription = autoSubmitDescription;
  static const String keypadStyle = 'Keypad style';
  static const String keypadStyleDescription = 'Choose your preferred numeric keypad layout';
  static const String resetData = 'Reset Data';
  static const String resetDataConfirmTitle = 'Reset All Data?';
  static const String resetDataConfirmMessage =
      'This will permanently delete all your practice history, high scores, '
      'and statistics. This action cannot be undone.';
  static const String resetDataSuccess =
      'All data has been reset successfully.';
  static const String about = 'About';
  static const String version = 'Version';

  // Practice Screen
  static const String timeLeft = 'Time Left';
  static const String score = 'Score';
  static const String streak = 'Streak';
  static const String enterAnswer = 'Enter answer';
  static const String quitConfirmTitle = 'Quit Practice Session?';
  static const String quitConfirmMessage =
      'Your progress so far will be saved as incomplete.';
  static const String quitWithoutSavingMessage =
      'No questions answered yet. Nothing will be saved.';
  static const String paused = 'Session Paused';
  static const String resumeSession = 'Resume';
  static const String startPractice = 'Start Practice';
  static const String practiceSetup = 'Practice Setup';
  static const String reviewMistakes = 'Review Mistakes';
  static const String noMistakes = 'Perfect score! Zero mistakes.';

  // Results Screen
  static const String sessionComplete = 'Session Complete!';
  static const String finalScore = 'Final Score';
  static const String accuracy = 'Accuracy';
  static const String correct = 'Correct';
  static const String incorrect = 'Incorrect';
  static const String wrong = 'Wrong';
  static const String skipped = 'Skipped';
  static const String totalQuestions = 'Total Questions';
  static const String timeSpent = 'Time Spent';
  static const String avgTimePerQuestion = 'Avg. Time / Question';
  static const String newHighScore = 'New High Score!';
  static const String newBestScore = 'New Best Score!';
  static const String newTop3Time = 'New Top-3 Time!';
  static const String speedBonus = 'Speed Bonus';

  // Stats Screen
  static const String bestScore = 'Best Score';
  static const String recentBestScore = 'Recent Best';
  static const String totalSessions = 'Total Sessions';
  static const String totalPracticeTime = 'Total Practice Time';
  static const String overallAccuracy = 'Overall Accuracy';
  static const String bestStreak = 'Best Streak';
  static const String performanceByTopic = 'Performance by Topic';
  static const String performanceByDifficulty = 'Performance by Difficulty';
  static const String recentSessions = 'Recent Sessions';
  static const String bestTimes = 'Best Times';
  static const String history = 'History';

  // Skill Levels
  static const String skillLevel = 'Skill Level';
  static const String notEnoughData = 'Not enough data';
  static const String needsWork = 'Needs work';
  static const String gettingThere = 'Getting there';
  static const String strong = 'Strong';

  // Greetings & Empty States
  static const String welcomeGreeting = 'Ready to Practice?';
  static const String welcomeSubtitle =
      'Train your brain with quick mental math drills.';
  static const String emptyStatsTitle = 'No Stats Yet';
  static const String emptyStatsMessage =
      'Complete your first practice session to start seeing your statistics!';
  static const String emptyHistoryMessage =
      'No practice sessions recorded yet.';

  // About
  static const String aboutText =
      'Speed Math with AI helps you build lightning-fast mental calculation '
      'skills for competitive exams. Practice daily and watch your speed grow!';
  static const String privacyNote =
      'This app works 100% offline. No data is collected or sent anywhere.';
}
