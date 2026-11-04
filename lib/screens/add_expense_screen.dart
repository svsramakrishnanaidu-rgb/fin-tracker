import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../models/expense_category.dart';
import '../providers/expense_provider.dart';
import '../services/expense_storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/category_selector.dart';

/// Screen 2 - add or edit an expense with full validation and safe saving.
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, this.expense});

  /// When provided the screen edits this expense instead of creating one.
  final Expense? expense;

  bool get isEditing => expense != null;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  ExpenseCategory? _category;
  DateTime _date = DateTime.now();
  String? _amountError;
  String? _categoryError;
  String? _dateError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final Expense? expense = widget.expense;
    _amountController = TextEditingController(
      text: expense == null ? '' : expense.amount.toStringAsFixed(2),
    );
    _noteController = TextEditingController(text: expense?.note ?? '');
    _category = expense?.category;
    _date = expense?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(today) ? today : _date,
      firstDate: DateTime(2000),
      lastDate: today,
      helpText: 'Select expense date',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _date.hour,
        _date.minute,
      );
      _dateError = null;
    });
  }

  Future<void> _save() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();

    final String raw = _amountController.text;
    final int? amountMinor = parseAmountToMinor(raw);
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime dateOnly = DateTime(_date.year, _date.month, _date.day);

    setState(() {
      _amountError = amountMinor == null
          ? (raw.trim().isEmpty
                ? 'Enter an amount'
                : 'Enter a valid amount greater than ₹0.00')
          : null;
      _categoryError = _category == null ? 'Choose a category' : null;
      _dateError = dateOnly.isAfter(today)
          ? 'The date cannot be in the future'
          : null;
    });

    if (_amountError != null || _categoryError != null || _dateError != null) {
      return;
    }

    setState(() => _isSubmitting = true);
    final ExpenseProvider provider = context.read<ExpenseProvider>();
    final String note = _noteController.text.trim();

    try {
      if (widget.isEditing) {
        await provider.updateExpense(
          widget.expense!.copyWith(
            amountMinor: amountMinor,
            category: _category,
            date: _date,
            note: note,
          ),
        );
      } else {
        await provider.addExpense(
          Expense.create(
            amountMinor: amountMinor!,
            category: _category!,
            date: _date,
            note: note,
          ),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on StorageException catch (error) {
      _showFailure(error.message);
    } catch (error) {
      _showFailure('The expense could not be saved. Nothing was changed.');
    }
  }

  void _showFailure(String message) {
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: context.colors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: IconButton(
            tooltip: 'Close',
            onPressed: _isSubmitting
                ? null
                : () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        title: Text(widget.isEditing ? 'Edit expense' : 'New expense'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 660),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                    children: <Widget>[
                      Text(
                        widget.isEditing ? 'Update the details below.' : 'Log what you spent and FinTrack keeps the rest in sync.',
                        style: text.bodySmall?.copyWith(
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _AmountField(
                        controller: _amountController,
                        errorText: _amountError,
                        enabled: !_isSubmitting,
                        onChanged: (_) {
                          if (_amountError != null) {
                            setState(() => _amountError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 22),
                      _SectionLabel(
                        label: 'CATEGORY',
                        trailing: _category?.label,
                      ),
                      const SizedBox(height: 10),
                      CategorySelector(
                        selected: _category,
                        enabled: !_isSubmitting,
                        errorText: _categoryError,
                        onChanged: (ExpenseCategory category) {
                          setState(() {
                            _category = category;
                            _categoryError = null;
                          });
                        },
                      ),
                      const SizedBox(height: 22),
                      const _SectionLabel(label: 'DATE'),
                      const SizedBox(height: 10),
                      _DateTile(
                        date: _date,
                        errorText: _dateError,
                        onTap: _isSubmitting ? null : _pickDate,
                      ),
                      const SizedBox(height: 22),
                      const _SectionLabel(label: 'NOTE', trailing: 'Optional'),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _noteController,
                        enabled: !_isSubmitting,
                        minLines: 3,
                        maxLines: 5,
                        maxLength: 500,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        style: text.bodyMedium?.copyWith(
                          fontSize: 14.5,
                          height: 1.45,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'What was this for?',
                          counterStyle: TextStyle(fontSize: 10.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _SaveBar(
              isEditing: widget.isEditing,
              isSubmitting: _isSubmitting,
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }
}

/// Always-visible primary action so saving never requires scrolling and stays
/// above the on-screen keyboard.
class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.isEditing,
    required this.isSubmitting,
    required this.onSave,
  });

  final bool isEditing;
  final bool isSubmitting;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextTheme text = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(
          top: BorderSide(color: colors.divider.withValues(alpha: 0.8)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 660),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSubmitting ? null : onSave,
                      child: isSubmitting
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.onPrimary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(isEditing ? 'Saving changes…' : 'Saving…'),
                              ],
                            )
                          : Text(isEditing ? 'Save changes' : 'Save expense'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 12,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Stored only on this device',
                          style: text.bodySmall?.copyWith(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.trailing});

  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Row(
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.6,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.errorText,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? errorText;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextTheme text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: errorText != null ? colors.danger : colors.divider,
          width: errorText != null ? 1.3 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'AMOUNT',
            style: text.labelSmall?.copyWith(
              letterSpacing: 1.8,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          TextField(
            controller: controller,
            enabled: enabled,
            autofocus: false,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              LengthLimitingTextInputFormatter(14),
            ],
            onChanged: onChanged,
            style: text.displaySmall?.copyWith(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.2,
            ),
            cursorColor: colors.primary,
            decoration: InputDecoration(
              filled: false,
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
              prefixText: '₹ ',
              prefixStyle: text.displaySmall?.copyWith(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
              hintText: '0.00',
              hintStyle: text.displaySmall?.copyWith(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary.withValues(alpha: 0.35),
              ),
              errorText: null,
              errorStyle: const TextStyle(height: 0, fontSize: 0),
            ),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.error_outline_rounded,
                    size: 13,
                    color: colors.danger,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      errorText!,
                      style: text.bodySmall?.copyWith(
                        color: colors.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.date,
    required this.errorText,
    required this.onTap,
  });

  final DateTime date;
  final String? errorText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: errorText != null ? colors.danger : colors.divider,
                  width: errorText != null ? 1.3 : 1,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colors.secondary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      size: 19,
                      color: colors.secondary,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          formatDateShort(date),
                          style: text.titleSmall?.copyWith(fontSize: 14.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatTime(date),
                          style: text.bodySmall?.copyWith(fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.edit_calendar_rounded,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 8),
            child: Text(
              errorText!,
              style: text.bodySmall?.copyWith(
                color: colors.danger,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
