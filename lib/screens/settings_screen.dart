import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';
import '../services/expense_storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/motion.dart';

/// Optional fifth screen: theme selection, local data controls and about info.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _clearData(BuildContext context) async {
    final ExpenseProvider provider = context.read<ExpenseProvider>();
    final int count = provider.transactionCount;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear all expense data?'),
          content: Text(
            count == 1
                ? 'This removes the 1 expense stored on this device. It cannot be undone.'
                : 'This removes all $count expenses stored on this device. It cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear data'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await provider.clearAll();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('All local expense data cleared')),
        );
    } on StorageException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: context.colors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = context.watch<ThemeProvider>();
    final ExpenseProvider expenseProvider = context.watch<ExpenseProvider>();
    final AppColors colors = context.colors;
    final TextTheme text = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 660),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 150),
            children: <Widget>[
              Text(
                'Settings',
                style: text.headlineLarge?.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 3),
              Text(
                'Make FinTrack feel like yours',
                style: text.bodySmall?.copyWith(fontSize: 12.5),
              ),
              const SizedBox(height: 22),
              _SectionTitle(label: 'Appearance', icon: Icons.palette_outlined),
              const SizedBox(height: 10),
              ...AppThemePreset.values.map(
                (AppThemePreset preset) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _ThemeTile(
                    preset: preset,
                    selected: themeProvider.preset == preset,
                    onTap: () => themeProvider.select(preset),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SectionTitle(label: 'Your data', icon: Icons.shield_outlined),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.elevated,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: colors.divider.withValues(alpha: 0.65),
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.smartphone_rounded,
                            size: 19,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                expenseProvider.isLoading
                                    ? 'Reading local storage…'
                                    : expenseProvider.transactionCount == 1
                                    ? '1 expense on this device'
                                    : '${expenseProvider.transactionCount} expenses on this device',
                                style: text.titleSmall?.copyWith(
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Total ${formatCurrency(expenseProvider.totalMinor)} · saved locally',
                                style: text.bodySmall?.copyWith(fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colors.divider.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            Icons.info_outline_rounded,
                            size: 15,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'FinTrack keeps everything offline using the app\'s local preferences. '
                              'No account, no network request. Local preferences are not encrypted '
                              'storage, so avoid storing sensitive card details in notes.',
                              style: text.bodySmall?.copyWith(
                                fontSize: 11.5,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: expenseProvider.isBusy
                            ? null
                            : () => _clearData(context),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.danger,
                        ),
                        icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                        label: const Text('Clear all expense data'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionTitle(label: 'About', icon: Icons.info_outline_rounded),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.elevated,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: colors.divider.withValues(alpha: 0.65),
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    const _AboutRow(
                      icon: Icons.bolt_rounded,
                      label: 'Version',
                      value: '1.0.0 (build 1)',
                    ),
                    Divider(
                      height: 1,
                      color: colors.divider.withValues(alpha: 0.6),
                    ),
                    const _AboutRow(
                      icon: Icons.wifi_off_rounded,
                      label: 'Works offline',
                      value: 'No internet required',
                    ),
                    Divider(
                      height: 1,
                      color: colors.divider.withValues(alpha: 0.6),
                    ),
                    const _AboutRow(
                      icon: Icons.flutter_dash_rounded,
                      label: 'Built with',
                      value: 'Flutter · Provider',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'FinTrack · Track smarter. Spend better. Live freely.',
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(
                    fontSize: 11,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Row(
      children: <Widget>[
        Icon(icon, size: 15, color: colors.textSecondary),
        const SizedBox(width: 7),
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.6,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final AppThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppPalette palette = paletteOf(preset);
    final TextTheme text = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      label: '${preset.label} theme',
      child: Material(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? palette.primary.withValues(alpha: 0.75)
                    : colors.divider,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: palette.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: palette.divider),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _SwatchDot(color: palette.primary),
                        const SizedBox(width: 4),
                        _SwatchDot(color: palette.secondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        preset.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        preset.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: context.motion(const Duration(milliseconds: 200)),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: selected ? palette.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? palette.primary : colors.divider,
                      width: 1.4,
                    ),
                  ),
                  child: selected
                      ? Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: palette.primary.computeLuminance() > 0.5
                              ? const Color(0xFF06120C)
                              : Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwatchDot extends StatelessWidget {
  const _SwatchDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: colors.textSecondary),
          const SizedBox(width: 11),
          Text(
            label,
            style: text.bodySmall?.copyWith(
              fontSize: 13,
              color: colors.textSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.titleSmall?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
