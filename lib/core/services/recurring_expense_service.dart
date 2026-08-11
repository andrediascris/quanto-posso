import 'package:quanto_posso/repositories/recurring_expense_repository.dart';

class RecurringExpenseService {
  RecurringExpenseService({RecurringExpenseRepository? repository})
    : _repository = repository ?? RecurringExpenseRepository();

  final RecurringExpenseRepository _repository;
  Future<int>? _activeGeneration;

  Future<int> generateDueOccurrences({DateTime? now}) {
    return _activeGeneration ??= _generate(now ?? DateTime.now());
  }

  Future<int> _generate(DateTime now) async {
    try {
      return await _repository.generateDueOccurrences(now);
    } finally {
      _activeGeneration = null;
    }
  }
}
