# PROJECT_STATE.md — Speed Math with AI

## Current Phase: Phase 7A.3 — UI & Behavior Fixes Complete ✅ (Version 1.4.1)

## What Is Finished

### Phase 1 — Project Setup ✅
- [x] Flutter project with `com.speedmathwithai`, minSdk 24, portrait, no INTERNET
- [x] Feature-first folder structure, Poppins font, Material 3 theme (light/dark)
- [x] go_router + bottom nav, splash screen, placeholder screens
- [x] Strings, enums, constants, FeatureFlags
- [x] SQLite database layer (sessions + attempts tables, models, repositories)

### Phase 2 — Question Engine ✅
- [x] **Question model** (`lib/domain/questions/question.dart`) — pure Dart, with topic, difficulty, displayText, operands list, correctAnswer
- [x] **QuestionGenerator interface** (`lib/domain/questions/question_generator.dart`) — abstract class with `generate()` and `generateUnique()`
- [x] **5 V1 generator classes** (Addition, Subtraction, Multiplication, Division, Squares)
- [x] **Session random utility** (`lib/domain/questions/session_random.dart`)
- [x] **Generator registry** (`lib/domain/questions/question_generator_registry.dart`)
- [x] **Score calculator** & **Session summary calculator**

### Phase 3 — Practice Flow ✅
- [x] SettingsRepository, Practice Setup, Keypad, Controller, Practice Session, Results

### Phase 4 — Stats and History ✅
- [x] Accuracy formula fix: `accuracy = correct / (correct + wrong + skipped)`
- [x] ModeValue isolation: queries strictly isolate `(topic, difficulty, mode, mode_value)`
- [x] Timer mode average time per correct answer
- [x] Stats screen, history line graph with fl_chart, session details, and debug sample data generator

### Phase 5 & 5.1 — UI Polish & Settings Changes ✅
- [x] Removed answer flash (instant transitions)
- [x] Phone dialer vs. Calculator keypad styles with live previews
- [x] Clean Home screen, redesigned Results screen with Score hero & accuracy ring
- [x] Modern design system with signature topic colors

### Phase 6A — New Topics & Skill Tracking ✅ (Version 1.1.0)
- [x] **4 New Pure Dart Question Generators** (Cubes, Square Roots, Cube Roots, Exponents)
- [x] **UI Support for 9 Topics** across Home, Practice Setup, Stats, and History
- [x] **Pure Dart Skill Tracking Engine** (`lib/domain/adaptive/`)
- [x] **Database Migration to Schema Version 3** with batched backfill
- [x] **Skill Level Card on Stats Screen**
- [x] **Rich Text Math Display** (`QuestionTextWidget`) for exponents

### Phase 6A.1 — Two Fixes & Size Check ✅ (Version 1.1.1)
- [x] **Fix 1: Wrong Answer Does NOT Advance**:
  - The question moves forward ONLY on a correct answer or Skip.
  - Zero visual change on wrong answers (no red text, no flash, no animation, no border change). Input stays intact.
  - **Auto-submit ON**: When the typed number reaches target answer length and is wrong, it is internally recorded as wrong once, plays the wrong sound and haptic once, does NOT advance, and keeps the text so the user can backspace and fix it.
  - **Auto-submit OFF**: Pressing Submit with a wrong value marks it wrong once and stays on question. Submit on empty does nothing.
  - **"First try counts"**: A question is marked wrong at most once. Subsequent wrong tries on the same question do not add extra wrongs or re-trigger sound. Correcting a previously failed question advances as usual, but scores 0 points, records `is_correct = 0`, stores the first wrong answer, and receives an adaptive skill outcome of 0.0.
  - **Skip after wrong try**: Recorded as wrong (`is_skipped = 0`, `is_correct = 0`). Skip without prior wrong try is recorded as skipped (`is_skipped = 1`).
  - **Flushing on Quit or Timer Expiry**: If the timer expires or the user quits while a question with an existing wrong try is on screen, it is automatically flushed and counted as wrong. If no wrong try was made, the question remains uncounted.
- [x] **Fix 2: Real Sounds & Non-Exclusive Playback**:
  - **Root Cause Reported**: `SystemSound.play(SystemSoundType.click)` relies on the Android OS setting "Touch sounds / Touch vibration" being enabled in device settings. When disabled (default on most modern Android devices and emulators), `SystemSound` is completely muted by the OS. Furthermore, `SystemSound` cannot differentiate pitches for correct vs wrong answers.
  - **Audio Engine**: Added `audioplayers: ^6.7.1` behind an abstract `SoundService` interface (`AppSoundService`).
  - **Sound Assets Generated**:
    * `assets/sounds/correct.wav`: 9,746 bytes (clean rising dual chime, $660 \to 880\text{ Hz}$).
    * `assets/sounds/wrong.wav`: 9,746 bytes (soft low gentle buzz, $140\text{ Hz}$ with sub-harmonics).
    * Both assets declared in `pubspec.yaml` (< 20 KB limit satisfied).
  - **Audio Focus**: Configured `AudioContextAndroid` with `AndroidAudioFocus.none` and `AudioContextIOS` with `AVAudioSessionCategory.ambient` + `mixWithOthers`, ensuring background music (Spotify, podcasts) is never paused or ducked.
  - **Sound Setting**: Live toggle; turning Sound ON in Settings plays a preview of `correct.wav`. Silent failure handling prevents any crash if audio hardware is absent.
  - **Haptic Feedback**: Retained with heavier haptic impact on wrong answers (`heavyImpact()`) vs correct answers (`lightImpact()`).
- [x] **Check 3: App Size & Safe Reductions**:
  - Baseline single fat APK: 50.8 MB (contains 3 native architectures).
  - Split-per-ABI APKs:
    * `app-arm64-v8a-release.apk`: **18.7 MB** (per-device download for ~95% of modern Android devices)
    * `app-armeabi-v7a-release.apk`: **16.2 MB**
    * `app-x86_64-release.apk`: **19.9 MB**
  - AppBundle: `app-release.aab`: **43.5 MB** (Google Play dynamically delivers the ~18 MB slice per device).
  - Safe reductions applied:
    * Enabled R8 minification (`isMinifyEnabled = true`) and resource shrinking (`isShrinkResources = true`) with custom `proguard-rules.pro`.
    * Removed unused `Poppins-Light.ttf` (saved 162 KB with zero UI impact).
    * Material icon tree-shaking verified active (99.5% icon font reduction).
  - Both per-device APK and Play Store slices are well under the **25 MB target**.
- [x] **Verification**:
  - `flutter analyze`: **0 issues found**.
  - `flutter test`: **153 of 153 tests passing** (100% pass rate).
  - Version bumped to **1.1.1** across `pubspec.yaml` and `AppConstants`.

### Phase 6B — Part A: Sound Settings & Volume ✅ (Version 1.2.0)
- [x] **Two Independent Sound Switches**:
  - "Correct answer sound" and "Wrong answer & skip sound", both default OFF.
  - Migration: legacy single Sound toggle migrated (if ON -> both ON; if OFF -> both OFF).
  - Previews: switching either switch ON in Settings plays that sound once as an instant preview.
  - Skip rule: skip without prior wrong try plays wrong sound; skip after a wrong try plays nothing extra.
- [x] **Media Volume Stream Fix**:
  - `MainActivity.kt`: Sets `volumeControlStream = AudioManager.STREAM_MUSIC` in `onCreate`.
  - `AppSoundService`: Configured with `STREAM_MUSIC` audio stream type and media usage attributes.
  - Hardware volume rocker keys adjust media volume while app is open even before sounds play.
- [x] **In-App Sound Volume Slider**:
  - 0% to 100% slider in Settings (default 100%), multiplied with device media volume.
  - Greyed out and disabled when both sound switches are OFF.
  - Releasing slider thumb plays `correct` sound preview at the selected volume.
- [x] **User MP3 Audio Files**:
  - User's `correct.mp3` and `wrong.mp3` installed in `assets/sounds/` and registered in `pubspec.yaml`.

### Phase 6B — Part B: Smart Practice Mode & Mistake Bank ✅ (Version 1.2.0)
- [x] **Database Migration to Schema Version 4**:
  - New table `mistake_bank` (id, topic, difficulty, question_text UNIQUE, operands JSON, correct_answer, stage 0-2, correct_streak, wrong_count, source, added_at, due_counter).
  - Index `idx_mistake_bank_due` on `(due_counter, stage, wrong_count)`.
  - Persisted global counter `smart_question_counter`.
  - Data reset: `SettingsRepository.resetAllData()` and `DebugSampleDataService.clearAllSampleData()` clear `mistake_bank` and reset the counter.
- [x] **Pure Dart Spaced Repetition Mistake Bank**:
  - Added on wrong answer, skipped question, or slow correct answer (> 2x target time).
  - Replay progression across 3 stages with gaps [3, 10, 25]:
    * Stage 0 -> correct -> stage 1, streak 1, due after 10 smart questions.
    * Stage 1 -> correct -> stage 2, streak 2, due after 25 smart questions.
    * Stage 2 -> correct -> streak 3 -> cleared and permanently removed from bank!
  - Replay wrong / skipped / slow resets to stage 0, streak 0, and increments wrong count.
  - Capacity eviction: hard cap of 300; evicts highest streak (stage 2) oldest items first.
- [x] **Pure Dart Smart Question Picker Engine** (`SmartQuestionPicker`):
  - 60% Weak / 30% Medium (including Not Enough Data) / 10% Strong candidate bucket mix.
  - Proportional weight redistribution when bucket classes are empty.
  - Mastery-weighted selection inside class: `w = 1.05 - mastery`.
  - Cold start unlock thresholds: Easy always unlocked; Medium/Hard unlock at 5 attempts & 0.50 mastery.
  - Difficulty nudge: 10-attempt sliding window (>= 85% accuracy nudges up; <= 60% accuracy nudges down).
  - Due mistakes interleaving: <= 1/3 of session, never 2 in a row.
  - Strict no-repeat-previous-question rule.
- [x] **Unified Question Source Abstraction** (`QuestionSource`):
  - `GeneratorQuestionSource` for single topic/difficulty practice.
  - `SmartQuestionSource` for Smart Practice.
  - `MistakeQuestionSource` for Mistake Practice.
- [x] **Practice Setup Screen**:
  - Hero "Smart Practice" card at top with multi-topic selection chips and question count selector (10, 20, 30).
  - "Practice your mistakes" card with banked mistake count badge, due questions preview, and shortcut.
  - Custom Practice section below for traditional single-topic drills.
- [x] **Mistakes Screen** (`/mistakes`):
  - Banked mistakes grouped by topic with signature topic colors.
  - Displays question text, correct answer, times wrong, and source badge.
  - Swipe-to-dismiss to manually remove resolved items.
  - "Practice these" button to drill up to 20 banked mistakes.
  - Friendly empty state when 0 mistakes are in the bank.
- [x] **Results Screen**:
  - Excludes best score / top-3 times badges for Smart and Mistake Practice.
  - Per-topic breakdown in signature topic colors (correct count, total count, avg time).
  - Mistake Bank metrics card displaying new banked mistakes, resolved mistakes, and remaining bank size.
- [x] **Home & History Integration**:
  - Last-session card handles `smart` and `mistakes` modes cleanly with `Smart Practice • Adaptive` and `Mixed (adaptive)`.
  - History screen has dedicated "Smart Practice" filter chip covering both smart and mistakes sessions.
  - Stats screen queries remain strictly isolated to standard topics and modes (Smart and Mistakes never taint best scores, top-3 times, or line graphs).
- [x] **Debug Sample Data Generator**:
  - Seeds ~15 realistic sample mistakes (stages 0, 1, 2) across topics and sources on "Generate Sample Data".
  - Cleans up `mistake_bank` on sample data reset.

### Phase 7A — Performance Report ✅ (Version 1.3.0)
- [x] **Small Fix**:
  - Smart Practice question count options include 10, 20, 30, and 50.
- [x] **Report Analyzer** (`lib/domain/report/report_analyzer.dart`):
  - Pure Dart with injectable `today` parameter for deterministic testing.
  - Uses SQL aggregates on `sessions`, `attempts`, `skill_ratings`, and `mistake_bank` tables without loading raw attempts into memory.
  - Generates structured `ReportData` comparing the last 7 days against the previous 7 days (`ReportConstants.windowDays = 7`).
  - Overall Speed Score (0-100): weighted average of mastery over all standard topic+difficulty buckets with at least 5 attempts (weight = min(attempts, 50) * 100). Categorized as Beginner (<40), Building (40-60), Strong (60-80), Elite (80+). Returns null when no bucket has >= 5 attempts.
  - Weekly summary comparison: sessions, questions answered, practice minutes, accuracy, and average time per correct answer.
  - Per-topic breakdown: level from best-attempted difficulty summary, accuracy, avg time, total attempts, days since last practiced, and trend.
  - Trend evaluation rules: requires at least 15 answered questions in EACH 7-day window. "Improving" if avg time fell by 8%+ OR accuracy rose by 5 points+. "Slipping" if time rose by 8%+ OR accuracy fell by 5 points+. Otherwise "Steady". Otherwise "Not enough data".
  - Strong areas: up to 3 buckets with mastery >= 0.80.
  - Weak areas: up to 3 buckets with attempts >= 5 and lowest mastery (strictly < 0.65).
  - Neglected topics (not practiced for 7+ days) and never-practiced topics.
  - Mistake bank summary: total count and top 3 topics by mistake count.
- [x] **Today's Plan** (`lib/domain/report/todays_plan_generator.dart`):
  - 3 focused blocks (~5 min each, ~15 min total).
  - Block 1 & 2: two weakest buckets (different topics if possible), launching 5-minute Timer sessions.
  - Block 3: Mistake Practice (if mistakes in bank), else third weakest bucket, else "Keep it sharp" Smart Practice (20Q).
  - Cached per day in SharedPreferences so it remains stable during the day; refreshed on a new day or Reset All Data.
  - Real-time Done detection: marks block Done when a completed matching session is saved today.
- [x] **Report Writer** (`lib/domain/report/report_writer.dart`):
  - Pure Dart text generator transforming `ReportData` into friendly, plain, encouraging, honest text sections.
  - Phrase bank in `assets/coach/phrases.json` with 28 situations and >= 4 variants each.
  - Deterministic date-seeded phrase selection (stable during the day, varies between days).
  - All numbers in text strictly match `ReportData` (never invented).
  - Clean regex verification guarantees zero unreplaced placeholders.
- [x] **Report Tab (UI)** (`lib/features/report/report_screen.dart`):
  - 5th bottom navigation tab: Home, Practice, Stats, Report, Settings (`AppStrings.tabReport = 'Report'`).
  - Ordered sections: Speed Score hero card with circular progress ring & label; Today's Plan with Start buttons and Done checkmarks; This week vs last week metric comparison cards; Strong areas; Needs work; Trends & Shifts; 9-Topic breakdown table in topic colors; Mistakes summary card.
  - Empty state when total questions < 20 with progress bar and "Start Smart Practice" button.
  - Async loading with loading and error states. Responsive without overflow at 360px and 1.3x text scale.
- [x] **Home Summary Card** (`lib/features/home/widgets/home_report_card.dart`):
  - Compact card above topic grid on Home: Speed Score with label, top insight sentence, "Today's plan: X of 3 done" with progress indicator, and tap-through to Report tab. Shows "Practice to unlock" when < 20 questions.
### Phase 7A.1 — Three Fixes: Idempotent Finish, Perceptual Volume Curve, Report Wording ✅ (Version 1.3.1)
- [x] **Fix 1: Results Screen Showing Twice & Duplicate Saved Data**:
  - **Root Cause Reported**: When a session completed, the controller's internal transition (`_recordCorrectAndAdvance`, `skip`, or `tick`) invoked `finishSession()`, changing state to `completed`. Concurrently, `PracticeSessionScreen`'s `ref.listen` listened for `next.status == completed` and invoked `controller.finishSession()` a second time. Without an idempotency future or navigation guard, `_saveSessionData(completed: true)` ran twice concurrently, producing duplicate rows in `sessions` and `attempts`, double-incrementing `smart_question_counter` (+20 instead of +10), duplicate writes to `skill_ratings` and `mistake_bank`, and pushing duplicate `/results` routes to the navigation stack.
  - **Controller Idempotency**: Added `_finishFuture`, `_isFinishing`, `_isFinished`, and `_cachedResultData` to `PracticeSessionController`. All actions (`tick`, `inputDigit`, `submit`, `skip`, `pause`, `resume`) are guarded. Both `finishSession()` and `quit()` return the existing `_finishFuture` if already in progress or completed, guaranteeing single execution.
  - **Navigation & Launch Guards**: Added `_hasNavigated` guard in `PracticeSessionScreen` ensuring `context.pushReplacement('/results')` runs exactly once. Added `_isLaunching` debounce guards in `PracticeSetupScreen` and `MistakesScreen` to prevent rapid double-taps from spawning parallel practice sessions.
  - **Regression Tests**: Added 6 tests in `practice_session_controller_test.dart` and 3 tests in `practice_session_fresh_db_test.dart` asserting that multiple triggers save exactly 1 session, 1 set of attempts, increment smart counter once, and update skill ratings once even on an empty database.
- [x] **Fix 2: Sound Volume Curve & Loudness Audit**:
  - **Loudness Audit Results** (via `ffmpeg volumedetect`):
    * `assets/sounds/correct.mp3`: max_volume: 0.0 dBFS (full digital saturation), mean_volume: -15.0 dBFS.
    * `assets/sounds/wrong.mp3`: max_volume: -19.9 dBFS, mean_volume: -24.4 dBFS.
    * Files were not modified.
  - **Root Cause Reported**: Hearing follows a power curve ($L \sim A^{0.33}$). A linear amplitude of 0.10 sounds like ~46% loudness, explaining why low slider values still sounded loud. Additionally, `audioplayers` `play()` calls were not directly receiving the volume parameter, which could cause Android `SoundPool` to default to 1.0 amplitude.
  - **Perceptual Volume Curve**: Added `SoundConstants.perceptualVolumeExponent = 3.0` power curve (`effectiveVolume = sliderValue^3.0`). Slider value 0.10 now maps to effective volume $0.10^3 = 0.001$, creating a soft whisper at low settings.
  - **Settings Slider & Preview**: Updated `_SoundVolumeSlider` to 20 discrete divisions (5% increments from 0% to 100%), passing `volume: effectiveVolume` directly on every `player.play()` call, and previewing audio only on slider release.
- [x] **Fix 3: Report Wording & Directionality**:
  - **Speed Comparisons**: Phrases now strictly state "fell by {speed_diff}, now {avg_time}", "{speed_diff} faster", or "dropped by {speed_diff}" when time decreases (never "up"). When time increases, phrases state "rose by {speed_diff}, now {avg_time}" or "{speed_diff} slower".
  - **Accuracy Comparisons**: Weekly accuracy comparisons strictly format differences as percentage points (e.g. `8 points`, never `8%`).
  - **Phrases Updated**: Updated all phrases across all 28 situations in `assets/coach/phrases.json` and in-memory fallback `_defaultPhrases` in `ReportWriter`.
- [x] **Test Suite & Static Analysis**:
  - 235 of 235 tests passing (100% pass rate).
  - `flutter analyze` reports 0 issues.
  - Version bumped to **1.3.1** across `pubspec.yaml` and `AppConstants`.

### Phase 7A.2 — Fixes, Unified Practice Screen & Mistakes Rework ✅ (Version 1.4.0)

#### Canonical Difficulty Ranges Table (`DifficultyRanges`)
All 9 question generators read exclusively from `DifficultyRanges` (`lib/domain/questions/difficulty_ranges.dart`):

| Topic | Easy | Medium | Hard | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Addition** | 2-digit + 2-digit ($10..99$) | 3-digit + 3-digit ($100..999$) | Three numbers of 3 to 4 digits ($100..9999$) | — |
| **Subtraction** | 2-digit − 2-digit ($10..99$) | 3-digit − 3-digit ($100..999$) | 4-digit − 4-digit ($1000..9999$) | Never negative ($a \ge b$) |
| **Multiplication** | 2-digit × 1-digit ($10..99 \times 2..9$) | 2-digit × 2-digit ($10..99 \times 10..99$) | 3-digit × 2-digit ($100..999 \times 10..99$) | — |
| **Division** | 2-digit ÷ 1-digit ($divisor \in 2..9$) | 3-digit ÷ 1-digit ($q \in 30..150$) OR 2-digit ÷ 2-digit ($d \in 11..25, q \in 3..9$) | 4-digit ÷ 2-digit ($divisor \in 11..99$) | Always exact division |
| **Squares** | $2^2$ to $20^2$ ($n \in 2..20$) | $21^2$ to $50^2$ ($n \in 21..50$, no mult 10) | $51^2$ to $99^2$ ($n \in 51..99$, no mult 10) | Multiples of 10 excluded in Med/Hard |
| **Cubes** | $2^3$ to $10^3$ ($n \in 2..10$) | $11^3$ to $20^3$ ($n \in 11..20$) | $21^3$ to $35^3$ ($n \in 21..35$, no mult 10) | Multiples of 10 excluded in Hard |
| **Square Roots** | Perfect squares up to $20^2$ ($\le 400$) | Perfect squares $21^2$ to $50^2$ ($441..2500$) | Perfect squares $51^2$ to $99^2$ ($2601..9801$) | Radical sign vector painter |
| **Cube Roots** | Perfect cubes $2^3$ to $10^3$ ($8..1000$) | Perfect cubes $11^3$ to $20^3$ ($1331..8000$) | Perfect cubes $21^3$ to $35^3$ ($9261..42875$) | Displayed as `³√n` with vector radical |
| **Exponents** | Base $2..9$, power $2..3$ | Base $2..9$, power $2..5$ | Base $2..15$, power $3..6$ | Result $\le 1,000,000$, base $\ne 1, 10$ |

#### Part A: Fixes
- [x] **A1: Difficulty Ranges Root Cause & Single Source of Truth**:
  - **Root Cause**: `PracticeConfig` / `SessionConfig` when launched via shortcuts or previous setup state could default or fall back to `Difficulty.easy` while the generator or picker used loose bounds, or `squares_generator.dart` had previously allowed lower bounds starting from 1 or arbitrary ranges.
  - **Fix**: Centralized all min/max bounds and exclusions into a single immutable domain structure: `DifficultyRanges` in `lib/domain/questions/difficulty_ranges.dart`. Refactored all 9 generators to read directly from it. 54 session-level range tests in `session_difficulty_ranges_test.dart` guarantee every question across every topic and difficulty strictly stays inside canonical bounds.
- [x] **A2: Missing Font Characters & Shared Question Widget**:
  - **Audit of Poppins Font Glyphs**:
    * Cube root character `∛` (U+221B): **Missing** in Poppins TTF files. Displayed as a broken box/fallback glyph.
    * Superscript 3 `³` (U+00B3): **Present and fully supported** in Poppins.
    * Square root radical `√` (U+221A): Present, but does not span horizontally over multi-digit radicands.
  - **Resolution**:
    * Updated `Topic.cubeRoots.symbol` from `'∛'` to `'³√'`.
    * Upgraded `QuestionTextWidget` (`lib/core/widgets/question_text_widget.dart`) with custom vector `_RadicalPainter` to draw a clean mathematical radical symbol with horizontal overline covering the radicand at any text scale.
    * Standardized math rendering across Practice Session, Results, and My Mistakes screens.
- [x] **A3: Quit Policy Rework**:
  - **3-Choice Dialog**:
    1. *Keep practicing* (cancels dialog, resumes timer/session).
    2. *End and see results* (ends session gracefully, sets `completed = 0`, saves session and attempts, updates skill ratings and mistakes, excludes from high scores/badges, and shows Results with "Ended early" badge).
    3. *Discard session* (stops immediately, saves 0 rows, deletes no prior data, returns to previous screen).
  - **Controller Idempotency**: `discard()` permanently marks session abandoned and cancels pending operations.

#### Part B: One Unified Practice Screen
- [x] **B1: Database Schema Migration to Version 5**:
  - Added `kind TEXT NOT NULL DEFAULT 'drill'` column to `sessions` table.
  - Migration backfills existing sessions: `smart` mode $\to$ `'mixed'`, `mistakes` mode $\to$ `'mistakes'`, all other sessions $\to$ `'drill'`.
  - Added index `idx_sessions_kind` on `sessions(kind)`.
- [x] **B2: Stats & High Scores Separation**:
  - `StatsRepository` queries for best scores, top-3 times, recent sessions, and graphs now enforce `WHERE kind = 'drill' AND completed = 1`.
  - Mixed sessions and mistake drills never pollute single-topic high scores or time leaderboards.
- [x] **B3 & B4: Unified Practice Setup Screen & SessionConfig**:
  - Single screen replacing duplicate tabs/modes.
  - **Weak Spots Chips**: Quick-select chips at top highlighting up to 3 weak topics (tapping selects 1 topic, Auto difficulty, Focus weak ON).
  - **Topic Selector**: Multi-select topic chips (1 to 9). "All topics" toggle chip selects/deselects all. Prevents deselecting the last remaining topic.
  - **Segmented Difficulty**: Auto, Easy, Medium, Hard with live contextual subtitle explaining the choice (e.g. "Adapts to your skill level per topic", "Single-digit drills").
  - **Focus on my weak areas switch**: Visible when multiple topics or Auto difficulty selected; automatically hidden when 1 topic + fixed difficulty selected.
  - **Target Selector**: Mode pills for Timer (1, 2, 3, 5, 10 min) and Questions (10, 20, 30, 50).
  - **Live Summary Line**: E.g., `Mixed • Auto difficulty • 20 questions` or `Addition • Easy • 5 min`.
  - **Sticky Start Button**: Anchored at bottom with clear launch action.
  - **"Practice my mistakes" Card**: Appears above Custom drill section when mistakes exist, showing count badge and direct action.
  - **Unified SessionConfig**: Encapsulates `kind`, `topics`, `difficulty`, `mode`, `modeValue`, `focusWeakAreas`, and audio preferences.
- [x] **B5 & B6: Label Updates & Launch Shortcuts**:
  - Removed "Smart Practice" terminology across all user-facing screens (`HomeScreen`, `HistoryScreen`, `SessionDetailsScreen`, `ReportScreen`, `TodaysPlanGenerator`).
  - Labeled cleanly as "Mixed" or "Mixed practice".
  - Home topic cards and Today's Plan launch pre-configured sessions into the unified practice engine.

#### Part C: Mistakes and Weak Spots
- [x] **C1: User-Facing Word Audit**:
  - Completely purged the words "bank" and "banked" from all user-visible strings, UI text, `assets/coach/phrases.json`, and fallback strings.
  - Replaced with clear, natural language: "My Mistakes", "mistakes to review", "mistake list", "Practice my mistakes".
  - Internal database tables (`mistake_bank`) and repository names (`MistakeRepository`) remain stable to preserve data integrity.
  - Verified by new automated test `test/core/strings/forbidden_strings_test.dart`.
- [x] **C2: "Practice my mistakes" Card on Practice Screen**:
  - Embedded prominently on Practice screen.
  - Shows total count of mistakes waiting for review and "See all" shortcut leading directly to `/mistakes`.
- [x] **C3: My Mistakes Screen Enhancements (`/mistakes`)**:
  - **Topic Filter Chips**: Horizontal filter chips (`All (X)`, followed by topics with mistakes). Selecting a chip filters displayed items and practice count.
  - **Grouped by Topic**: Sections with signature topic color indicators and math formatted via `QuestionTextWidget`.
  - **Practice Count Choice**: 10, 20, or All (up to 50) chips in sticky bottom bar with dynamic `Practice these (N)` button.
  - **Swipe-to-Dismiss with Undo SnackBar**: Swiping an item removes it from the list with an instant SnackBar offering an "Undo" action.


### Phase 7A.3 — UI and Behavior Fixes ✅ (Version 1.4.1)

- [x] **1. Remove Checkmarks from Chips**:
  - Removed checkmarks (`showCheckmark: false`) from ALL selectable chips across the app (`PracticeSetupScreen`, `MistakesScreen`, `HistoryScreen`, `StatsScreen`, `HistoryLineGraph`).
  - Implemented solid color fill in topic color with crisp white text, white topic symbol, and stronger font weight (`FontWeight.w600`) when selected.
  - "All topics" / "All" chip styled with solid neutral brand color (`colorScheme.primary`) and white text (`colorScheme.onPrimary`) when selected.
  - Unselected chips rendered with soft tinted background or clean outline and original topic color symbol.

- [x] **2. Reusable AppSegmentedControl**:
  - Created `AppSegmentedControl` (`lib/core/widgets/app_segmented_control.dart`) replacing Flutter's default `SegmentedButton` across the entire app (Practice Difficulty, Practice Mode, Settings Theme, Settings Keypad Style, Settings Vibration Strength, History line graph range).
  - Single-line guaranteed: labels never wrap, wrapped in `FittedBox(fit: BoxFit.scaleDown)` and `softWrap: false`.
  - Animated width flex: selected segment smoothly expands to 1.6x width over 220ms with a clean check icon next to its label, while unselected segments scale to 1.0x.
  - Responsive down to 360px screen width and 1.3x text scale with zero clipping and zero overflow errors.

- [x] **3. Base Number Invisible in Squares & Cubes (Root Cause & Fix)**:
  - **Root Cause**: `QuestionTextWidget._PowerTextWidget` rendered using raw `RichText(text: TextSpan(style: style, children: [TextSpan(text: base), ...]))`. In Flutter, unstyled `TextSpan` inside `RichText` defaults to `Color(0xFFFFFFFF)` (white). On white/light backgrounds, this resulted in white text on white background (invisible). The exponent child in `WidgetSpan` was a `Text` widget which inherited dark ink from `DefaultTextStyle.of(context)`.
  - **Fix**: Updated `QuestionTextWidget` to resolve explicit ink color from context (`style?.color ?? defaultStyle.color ?? themeColor`). Switched `_PowerTextWidget` to `Text.rich` using `resolvedStyle` across both base and exponent with consistent baseline offset.

- [x] **4. Results Screen Headline & Review Skips**:
  - "Perfect score! Zero mistakes." message appears ONLY when every question was answered and all were correct (0 wrong, 0 skipped).
  - When all questions are skipped, displays: *"You skipped every question. Try answering, even slowly, speed comes later."*
  - Included skipped questions in the Results mistake review list with their correct answers and a visible "Skipped" badge.

- [x] **5. Report Screen Unlock & Speed Score Messaging (Root Cause & Fix)**:
  - **Root Cause**: `ReportConstants.minTotalQuestionsForReport` was set to 20, locking out users who practiced a 10-question drill. Furthermore, `_getTotalQuestionsAllTime` counted all attempts instead of filtering answered questions (`WHERE is_skipped = 0`).
  - **Fix**: Reduced unlock threshold to 10 answered questions (`WHERE is_skipped = 0`).
  - Added "Early report" indicator banner when total answered questions is between 10 and 40.
  - When Speed Score has no bucket with $\ge 5$ attempts, the hero card clearly explains: *"Your Speed Score appears after 5 answers in the same topic and level (X answers still needed)"*, while keeping all other report sections visible.
  - Empty-state button updated to "Start practice".

- [x] **6. Haptics (Vibration) Motor Support (Root Cause & Fix)**:
  - **Root Cause**: Flutter's native `HapticFeedback` delegates to Android's `View.performHapticFeedback()`. When the Android OS setting "Touch feedback" / "Haptic feedback" is toggled off in device settings or battery saver is active, `performHapticFeedback` calls are silently dropped by the Android OS.
  - **Fix**: Added `vibration: ^3.1.8` and declared `<uses-permission android:name="android.permission.VIBRATE"/>` in `AndroidManifest.xml` (no INTERNET permission).
  - Created `AppHapticService` with strength scaling (Light, Medium, Strong), durations (key press ~12ms, correct ~22ms, wrong ~60ms, celebration double pulse), and safe fallback to `HapticFeedback`.
  - Added "Vibration strength" segmented control in Settings under Haptics with live preview on touch.
  - Updated Haptics setting description to *"Vibrate on key presses, answers and results"*.

- [x] **7. Exponents Hard Range Pool**:
  - Upgraded hard exponents in `lib/domain/questions/generators/exponents_generator.dart` to static precomputed pool covering bases 2 to 15, powers 3 to 6, strictly excluding bases 1 and 10 and results $> 1,000,000$.

---

### Phase 7B — On-Device AI Coach ✅ (Version 1.5.0)

- [x] **1. Pure Dart Coach Engine (`lib/domain/coach/`)**:
  - **Zero Packages & No Network**: 100% on-device, pure Dart implementation with no dependencies, no external APIs, and sub-15ms classification latency.
  - **Text Sanitization & Shorthand Mapping (`TextNormalizer`)**:
    - Converts input to lowercase, trims length to 300 characters, removes punctuation.
    - Resolves shorthand, typos, and synonyms: `mul`/`mult`/`times` $\to$ `multiplication`, `div`/`divison` $\to$ `division`, `sub`/`minus` $\to$ `subtraction`, `add`/`sum` $\to$ `addition`, `sq`/`square` $\to$ `squares`, `sqrt`/`sq root` $\to$ `square roots`, `cbrt`/`cube root` $\to$ `cube roots`, `cube` $\to$ `cubes`, `power`/`exponent`/`index` $\to$ `exponents`.
  - **Fast N-Gram & TF-IDF Classifier (`NgramIntentClassifier`)**:
    - Hybrid character 3-gram Sørensen-Dice coefficient combined with word-level TF-IDF cosine similarity.
    - Pre-indexed dictionary loaded once from `assets/coach/intents.json` (20 distinct intents with 20+ examples each).
    - Threshold confidence check (`CoachConstants.confidenceThreshold = 0.28`). Unknown queries or confidence below threshold safely fall back to friendly suggestions.
  - **Slot Extraction (`SlotExtractor`)**:
    - Topics: all 9 canonical drill topics.
    - Difficulty: Easy, Medium, Hard (and synonyms like "simple", "tough", "advanced").
    - Target Question Count: snapped to 10, 20, 30, 50.
    - Target Minutes: snapped to 1, 2, 3, 5, 10.
    - Time horizons: today, this week, last week.
  - **Contextual Follow-Up**:
    - Retains previous intent when follow-up messages provide new topics or slots (e.g. "what about cubes?" or "and subtraction").
  - **Factual Grounding (`CoachContext`)**:
    - Responses strictly derived from user's local database via `ReportAnalyzer` (`ReportData`), skill ratings, mistake count, today's plan, and recent sessions.
    - Under 10 answered questions: acknowledges early progress (X of 10) while answering general questions, tips, and practice setups normally.

- [x] **2. Grounded Answer Composer (`CoachComposer`)**:
  - Rotates through 4+ natural phrase variants per situation from `assets/coach/coach_phrases.json` without repeating the same variant twice in a row.
  - Replaces all placeholders (`{topic}`, `{percent}`, `{score}`, `{time}`, etc.) with 100% real math data; falls back to placeholder-free variants if values are missing.
  - Strict tone: honest, encouraging, short sentences. Accuracy in "points", time reductions in "faster", never uses the words "IQ" or "bank".
  - Mathematically verified tips from `assets/coach/tips.json` (27 verified math shortcuts across all 9 topics).
  - Emits interactive `CoachAction` buttons: `Start practice` (pre-filled with configured topic/difficulty/target), `Open report`, `Practice my mistakes`, `Open stats`.

- [x] **3. UI & Chat Presentation (`/coach`)**:
  - Accessible via "Ask Coach" button on Home report card and Coach icon button in Report screen header.
  - Chat layout with Coach messages on left (with avatar), User messages on right, responsive bubbles down to 360px and 1.3x text scale.
  - Top horizontally scrollable chip bar with ready-made questions (no checkmarks).
  - "Report this answer" action on coach messages with local SQLite persistence and user confirmation.
  - Chat history restored from SQLite; "Clear chat" menu in AppBar.
  - Persistent bottom disclaimer: *"Coach answers come from your practice on this phone. It cannot answer general questions."*

- [x] **4. Database Schema Version 6 (`DatabaseHelper`)**:
  - `coach_messages`: `id`, `role`, `text`, `actions` (JSON), `created_at`. Automatically pruned to the last 100 messages.
  - `coach_reports`: `id`, `created_at`, `user_message`, `coach_reply`, `reason`. Preserved locally for debugging.
  - `resetAllData()` updated to clear both Coach tables.
  - All existing user practice data, attempts, and skill ratings preserved during migration.

---

### How to Add a New Intent

Adding a new intent to the Coach is designed to be modular and require changes in only 4 places:

1. **Add Examples to `assets/coach/intents.json`**:
   Add a new key under `"intents"` with at least 20 natural phrasing examples, including typos, abbreviations, and informal speech:
   ```json
   "my_new_intent": [
     "how do i do X",
     "tell me about X",
     "explain X to me",
     ...
   ]
   ```

2. **Add Enum Value in `lib/domain/coach/coach_intent.dart`**:
   Add the enum case to `CoachIntent` and map it in `CoachIntent.fromKey`:
   ```dart
   enum CoachIntent {
     ...
     myNewIntent;

     static CoachIntent fromKey(String key) {
       switch (key) {
         ...
         case 'my_new_intent':
           return CoachIntent.myNewIntent;
       }
     }
   }
   ```

3. **Add Response Variants to `assets/coach/coach_phrases.json`**:
   Define at least 4 natural response variants with optional placeholders:
   ```json
   "my_new_intent": [
     "Here is how X works for your practice: {detail}.",
     "Looking at your numbers, {detail}.",
     "Regarding X, {detail} is what you should keep in mind.",
     "Let's look at X: {detail}."
   ]
   ```

4. **Add Handler in `CoachComposer` (`lib/domain/coach/coach_composer.dart`)**:
   Add a `case CoachIntent.myNewIntent:` in the `compose()` method and wire up the handler method using real data from `context`:
   ```dart
   case CoachIntent.myNewIntent:
     return _composeMyNewIntent(slots, context);
   ```

---

## What Is NOT Finished
- Phase 7C: Exam Packs, Tricks, Streaks & Reminders.

---

## How To Run
```bash
cd "/Users/rameez/Desktop/Speed Math"
flutter pub get
flutter analyze      # 0 issues
```

---

## What to Check by Hand (Phase 7B Checklist)

1. **Accessing the Coach**:
   - Tap "Ask Coach" button on Home report card $\to$ opens `/coach` chat screen.
   - Tap Coach icon in Report screen AppBar $\to$ opens `/coach` chat screen.
   - Verify initial welcome message from the Coach is displayed.
2. **Ready-Made Question Chips**:
   - Verify horizontal chip row at the top (without checkmarks): "Generate my report", "Where am I weak?", "Where should I focus?", "How is my division?", "Make me a plan for today", "Am I improving?", "My mistakes", "Give me a tip".
   - Tap "Where am I weak?" $\to$ message sends immediately, Coach responds with weakest buckets and "Practice this" button.
   - Tap "Start practice" on any action button $\to$ navigates into the unified Practice flow with correct topic, difficulty, and question count pre-filled.
3. **Typo & Shorthand Tolerance**:
   - Type `"wher am i wek"` $\to$ Coach answers with weak areas.
   - Type `"hw is my divison"` $\to$ Coach answers with Division accuracy, average time, and level.
   - Type `"sq root status"` $\to$ Coach answers with Square Roots status.
   - Type `"cbrt tip"` $\to$ Coach gives a verified math shortcut for Cube Roots.
4. **Follow-Up Context**:
   - Type `"How is my addition?"` $\to$ Coach answers with Addition status.
   - Follow up with `"what about cubes?"` $\to$ Coach answers with Cubes status.
5. **Start Practice Queries**:
   - Type `"practice squares hard 20 questions"` $\to$ Coach confirms: topic: Squares, level: Hard, 20 questions, and displays "Start Practice" button. Tapping the button launches the session.
   - Type `"5 minutes of addition easy"` $\to$ Coach confirms Addition, Easy, 5 minutes with "Start Practice" button.
6. **Out of Scope Handling**:
   - Type `"who won the cricket match yesterday"` or `"what is the weather in London"` $\to$ Coach politely explains it only helps with mental math practice on this phone and offers suggestions.
7. **Report an Answer**:
   - Tap "Report this answer" on any Coach reply $\to$ dialog appears with radio options (Wrong numbers, Not helpful, Offensive, Other).
   - Select an option and submit $\to$ shows confirmation SnackBar "Thanks, saved on your phone."
8. **Chat Persistence & Clear**:
   - Send several messages, exit the Coach screen, and re-enter $\to$ chat history is preserved.
   - Tap the overflow menu $\to$ "Clear chat" $\to$ conversation is cleared and fresh welcome message appears.
9. **Early State (< 10 questions)**:
   - On a fresh install or reset, open Coach $\to$ Coach clearly states how many questions remain before full stats unlock (X of 10), while still answering tips, greetings, and practice setups.
10. **Terminology Audit**:
    - Verify the words "IQ" and "bank" never appear in any Coach message or UI text.


