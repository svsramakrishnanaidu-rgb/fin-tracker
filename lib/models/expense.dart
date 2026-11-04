import 'dart:math';

import 'expense_category.dart';

/// A single expense record.
///
/// Amounts are stored as an integer number of paise so totals are exact.
class Expense {
  const Expense({
    required this.id,
    required this.amountMinor,
    required this.category,
    required this.date,
    required this.note,
    required this.createdAt,
  });

  /// Creates a new expense with a collision-resistant local identifier.
  factory Expense.create({
    required int amountMinor,
    required ExpenseCategory category,
    required DateTime date,
    String note = '',
    DateTime? createdAt,
  }) {
    final DateTime now = createdAt ?? DateTime.now();
    final int salt = _random.nextInt(0x7fffffff);
    return Expense(
      id: 'ft-${now.microsecondsSinceEpoch.toRadixString(36)}-${salt.toRadixString(36)}',
      amountMinor: amountMinor,
      category: category,
      date: date,
      note: note,
      createdAt: now,
    );
  }

  static final Random _random = Random();

  final String id;

  /// Amount in paise. Never zero or negative for a persisted expense.
  final int amountMinor;
  final ExpenseCategory category;

  /// The calendar day the money was spent.
  final DateTime date;

  /// Free-form note, may be empty. Stored and displayed in full.
  final String note;

  /// When the record was first written, kept for the detail screen.
  final DateTime createdAt;

  double get amount => amountMinor / 100;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'amountMinor': amountMinor,
    'category': category.name,
    'date': date.toIso8601String(),
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };

  /// Parses a stored record. Throws [FormatException] when the payload is not a
  /// usable expense so callers can skip the bad row without losing the rest.
  factory Expense.fromJson(Map<String, dynamic> json) {
    final Object? id = json['id'];
    final Object? amount = json['amountMinor'];
    final Object? date = json['date'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Expense id is missing');
    }
    if (amount is! int || amount <= 0) {
      throw const FormatException('Expense amount is invalid');
    }
    final DateTime? parsedDate = date is String
        ? DateTime.tryParse(date)
        : null;
    if (parsedDate == null) {
      throw const FormatException('Expense date is invalid');
    }
    final Object? createdAtRaw = json['createdAt'];
    final DateTime? parsedCreatedAt = createdAtRaw is String
        ? DateTime.tryParse(createdAtRaw)
        : null;
    final Object? note = json['note'];

    return Expense(
      id: id,
      amountMinor: amount,
      category: ExpenseCategory.fromStorage(json['category'] as String?),
      date: parsedDate,
      note: note is String ? note : '',
      createdAt: parsedCreatedAt ?? parsedDate,
    );
  }

  Expense copyWith({
    int? amountMinor,
    ExpenseCategory? category,
    DateTime? date,
    String? note,
  }) {
    return Expense(
      id: id,
      amountMinor: amountMinor ?? this.amountMinor,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }

  /// Short human friendly form of [id] for the detail screen.
  String get shortId =>
      id.length <= 10 ? id : id.substring(id.length - 8).toUpperCase();

  @override
  bool operator ==(Object other) =>
      other is Expense &&
      other.id == id &&
      other.amountMinor == amountMinor &&
      other.category == category &&
      other.date == date &&
      other.note == note &&
      other.createdAt == createdAt;

  @override
  int get hashCode =>
      Object.hash(id, amountMinor, category, date, note, createdAt);

  @override
  String toString() => 'Expense($id, ${category.label}, $amountMinor paise)';
}
