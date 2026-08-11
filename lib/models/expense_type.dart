enum ExpenseType {
  single('single'),
  subscription('subscription'),
  installment('installment');

  const ExpenseType(this.storageValue);
  final String storageValue;

  static ExpenseType fromStorage(String? value) =>
      ExpenseType.values
          .where((type) => type.storageValue == value)
          .firstOrNull ??
      ExpenseType.single;
}
