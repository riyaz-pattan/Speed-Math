/// Enumeration of all recognized user intents for the on-device AI Coach.
enum CoachIntent {
  greeting('greeting'),
  help('help'),
  reportSummary('report_summary'),
  weakAreas('weak_areas'),
  strongAreas('strong_areas'),
  focus('focus'),
  dailyPlan('daily_plan'),
  progress('progress'),
  topicStatus('topic_status'),
  speed('speed'),
  accuracy('accuracy'),
  mistakes('mistakes'),
  tips('tips'),
  motivation('motivation'),
  activity('activity'),
  startPractice('start_practice'),
  thanks('thanks'),
  goodbye('goodbye'),
  smalltalk('smalltalk'),
  outOfScope('out_of_scope'),
  unknown('unknown'),
  learn('learn'),
  habits('habits');

  const CoachIntent(this.key);
  final String key;

  static CoachIntent fromKey(String key) {
    for (final intent in CoachIntent.values) {
      if (intent.key == key) return intent;
    }
    return CoachIntent.unknown;
  }
}
