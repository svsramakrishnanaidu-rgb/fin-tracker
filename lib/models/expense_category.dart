/// The fixed set of FinTrack spending categories.
///
/// The [name] of each enum value is the storage key used in JSON, so renaming a
/// value is a data migration - append new categories instead of renaming.
enum ExpenseCategory {
  food('Food'),
  travel('Travel'),
  shopping('Shopping'),
  bills('Bills'),
  education('Education'),
  health('Health'),
  entertainment('Entertainment'),
  groceries('Groceries'),
  other('Other');

  const ExpenseCategory(this.label);

  /// Human readable name shown in the UI.
  final String label;

  /// Resolves a stored category name, falling back to [ExpenseCategory.other]
  /// for data written by a newer version of the app.
  static ExpenseCategory fromStorage(String? value) {
    for (final ExpenseCategory category in ExpenseCategory.values) {
      if (category.name == value) return category;
    }
    return ExpenseCategory.other;
  }
}
