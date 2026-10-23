import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/enums.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/strings/app_strings.dart';
import '../../core/widgets/app_segmented_control.dart';
import '../../data/repositories/settings_repository.dart';
import '../practice_session/widgets/keypad.dart';

/// Screen managing user preferences, keypad layout styles, theme selection,
/// tactile feedback, data reset, and about information.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _showResetConfirmDialog(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.resetDataConfirmTitle),
        content: const Text(AppStrings.resetDataConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(AppStrings.resetData),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final settings = ref.read(settingsRepositoryProvider);
      await settings.resetAllData();
      ref.read(dataRevisionProvider.notifier).state++;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.resetDataSuccess)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsRepositoryProvider);
    final currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.settings,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Appearance / Theme Section
            _buildSectionHeader('Appearance', colorScheme),
            const SizedBox(height: 8),
            _buildThemeSelector(context, ref, currentThemeMode, colorScheme),
            const SizedBox(height: 24),

            // Keypad Style Section with live preview
            _buildSectionHeader(AppStrings.keypadStyle, colorScheme),
            const SizedBox(height: 4),
            Text(
              AppStrings.keypadStyleDescription,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _buildKeypadStyleSelector(context, ref, settings, colorScheme),
            const SizedBox(height: 24),

            // Practice Experience Section
            _buildSectionHeader('Practice Experience', colorScheme),
            const SizedBox(height: 8),
            _buildCard([
              SwitchListTile(
                title: const Text(
                  AppStrings.autoSubmit,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  AppStrings.autoSubmitDescription,
                  style: TextStyle(fontSize: 12),
                ),
                value: settings.autoSubmit,
                onChanged: (val) async {
                  await settings.setAutoSubmit(val);
                  ref.invalidate(settingsRepositoryProvider);
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text(
                  AppStrings.haptics,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  AppStrings.hapticsDescription,
                  style: TextStyle(fontSize: 12),
                ),
                value: settings.hapticsEnabled,
                onChanged: (val) async {
                  if (val) {
                    ref.read(hapticServiceProvider).sample(strength: settings.vibrationStrength);
                  }
                  await settings.setHapticsEnabled(val);
                  ref.invalidate(settingsRepositoryProvider);
                },
              ),
              if (settings.hapticsEnabled) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vibration strength',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppSegmentedControl<VibrationStrength>(
                        selectedValue: settings.vibrationStrength,
                        items: const [
                          AppSegmentedItem(
                            value: VibrationStrength.light,
                            label: 'Light',
                          ),
                          AppSegmentedItem(
                            value: VibrationStrength.medium,
                            label: 'Medium',
                          ),
                          AppSegmentedItem(
                            value: VibrationStrength.strong,
                            label: 'Strong',
                          ),
                        ],
                        onValueChanged: (strength) async {
                          await settings.setVibrationStrength(strength);
                          ref.invalidate(settingsRepositoryProvider);
                          ref.read(hapticServiceProvider).sample(strength: strength);
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const Divider(height: 1),
              SwitchListTile(
                title: const Text(
                  AppStrings.correctSound,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  AppStrings.correctSoundDescription,
                  style: TextStyle(fontSize: 12),
                ),
                value: settings.correctSoundEnabled,
                onChanged: (val) async {
                  if (val) {
                    ref.read(soundServiceProvider).playCorrect();
                  }
                  await settings.setCorrectSoundEnabled(val);
                  ref.invalidate(settingsRepositoryProvider);
                },
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: settings.correctSoundEnabled
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: _InlineSoundVolumeSlider(
                  label: AppStrings.correctSoundVolume,
                  volume: settings.correctSoundVolume,
                  onChangedEnd: (val) async {
                    await settings.setCorrectSoundVolume(val);
                    await ref.read(soundServiceProvider).setCorrectVolume(val);
                    ref.read(soundServiceProvider).playCorrect();
                    ref.invalidate(settingsRepositoryProvider);
                  },
                ),
                secondChild: const SizedBox.shrink(),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text(
                  AppStrings.wrongSound,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  AppStrings.wrongSoundDescription,
                  style: TextStyle(fontSize: 12),
                ),
                value: settings.wrongSoundEnabled,
                onChanged: (val) async {
                  if (val) {
                    ref.read(soundServiceProvider).playWrong();
                  }
                  await settings.setWrongSoundEnabled(val);
                  ref.invalidate(settingsRepositoryProvider);
                },
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: settings.wrongSoundEnabled
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: _InlineSoundVolumeSlider(
                  label: AppStrings.wrongSoundVolume,
                  volume: settings.wrongSoundVolume,
                  onChangedEnd: (val) async {
                    await settings.setWrongSoundVolume(val);
                    await ref.read(soundServiceProvider).setWrongVolume(val);
                    ref.read(soundServiceProvider).playWrong();
                    ref.invalidate(settingsRepositoryProvider);
                  },
                ),
                secondChild: const SizedBox.shrink(),
              ),
            ], colorScheme),
            const SizedBox(height: 24),

            // Data Management Section
            _buildSectionHeader('Data Management', colorScheme),
            const SizedBox(height: 8),
            _buildCard([
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: colorScheme.error,
                ),
                title: Text(
                  AppStrings.resetData,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.error,
                  ),
                ),
                subtitle: const Text(
                  'Permanently delete all practice sessions and statistics',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () => _showResetConfirmDialog(context, ref),
              ),
            ], colorScheme),
            const SizedBox(height: 24),

            // About Section
            _buildSectionHeader(AppStrings.about, colorScheme),
            const SizedBox(height: 8),
            _buildCard([
              ListTile(
                title: const Text(
                  AppStrings.appName,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Works fully offline. Your data stays on your phone.',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPress: () => context.push('/settings/data-check'),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'v${AppConstants.appVersion}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ], colorScheme),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: colorScheme.primary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildCard(List<Widget> children, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildKeypadStyleSelector(
    BuildContext context,
    WidgetRef ref,
    SettingsRepository settings,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        AppSegmentedControl<KeypadStyle>(
          selectedValue: settings.keypadStyle,
          items: const [
            AppSegmentedItem<KeypadStyle>(
              value: KeypadStyle.phone,
              icon: Icons.dialpad_rounded,
              label: 'Phone dialer',
            ),
            AppSegmentedItem<KeypadStyle>(
              value: KeypadStyle.calculator,
              icon: Icons.calculate_outlined,
              label: 'Calculator',
            ),
          ],
          onValueChanged: (style) async {
            await settings.setKeypadStyle(style);
            ref.invalidate(settingsRepositoryProvider);
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () async {
                await settings.setKeypadStyle(KeypadStyle.phone);
                ref.invalidate(settingsRepositoryProvider);
              },
              child: KeypadPreviewWidget(
                style: KeypadStyle.phone,
                isSelected: settings.keypadStyle == KeypadStyle.phone,
              ),
            ),
            GestureDetector(
              onTap: () async {
                await settings.setKeypadStyle(KeypadStyle.calculator);
                ref.invalidate(settingsRepositoryProvider);
              },
              child: KeypadPreviewWidget(
                style: KeypadStyle.calculator,
                isSelected: settings.keypadStyle == KeypadStyle.calculator,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentMode,
    ColorScheme colorScheme,
  ) {
    return AppSegmentedControl<ThemeMode>(
      selectedValue: currentMode,
      items: const [
        AppSegmentedItem(
          value: ThemeMode.system,
          icon: Icons.brightness_auto_rounded,
          label: 'System',
        ),
        AppSegmentedItem(
          value: ThemeMode.light,
          icon: Icons.light_mode_rounded,
          label: 'Light',
        ),
        AppSegmentedItem(
          value: ThemeMode.dark,
          icon: Icons.dark_mode_rounded,
          label: 'Dark',
        ),
      ],
      onValueChanged: (newMode) {
        ref.read(themeModeProvider.notifier).setThemeMode(newMode);
      },
    );
  }
}

class _InlineSoundVolumeSlider extends StatefulWidget {
  final String label;
  final double volume;
  final ValueChanged<double> onChangedEnd;

  const _InlineSoundVolumeSlider({
    required this.label,
    required this.volume,
    required this.onChangedEnd,
  });

  @override
  State<_InlineSoundVolumeSlider> createState() =>
      _InlineSoundVolumeSliderState();
}

class _InlineSoundVolumeSliderState extends State<_InlineSoundVolumeSlider> {
  late double _current;

  @override
  void initState() {
    super.initState();
    _current = widget.volume;
  }

  @override
  void didUpdateWidget(covariant _InlineSoundVolumeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.volume != widget.volume) {
      _current = widget.volume;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (_current * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
            ),
            child: Slider(
              value: _current.clamp(0.0, 1.0),
              min: 0.0,
              max: 1.0,
              divisions: 20,
              onChanged: (val) {
                setState(() => _current = val);
              },
              onChangeEnd: (val) {
                widget.onChangedEnd(val);
              },
            ),
          ),
        ],
      ),
    );
  }
}
