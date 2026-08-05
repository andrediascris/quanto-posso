import 'package:flutter_test/flutter_test.dart';
import 'package:quanto_posso/core/utils/currency_utils.dart';

void main() {
  group('CurrencyUtils.tryParse', () {
    test('converte formatos monetários aceitos pelo aplicativo', () {
      expect(CurrencyUtils.tryParse('3500'), 3500);
      expect(CurrencyUtils.tryParse('3500,00'), 3500);
      expect(CurrencyUtils.tryParse('3.500,00'), 3500);
      expect(CurrencyUtils.tryParse('1250.90'), 1250.90);
      expect(CurrencyUtils.tryParse('3.500'), 3500);
      expect(CurrencyUtils.tryParse('R\$ 1.250,90'), 1250.90);
    });

    test('retorna null para entradas inválidas', () {
      expect(CurrencyUtils.tryParse(''), isNull);
      expect(CurrencyUtils.tryParse('valor'), isNull);
      expect(CurrencyUtils.tryParse('1.2.3'), isNull);
    });
  });

  test('formata moeda e valor de entrada em pt_BR', () {
    expect(CurrencyUtils.format(1250.90), contains('1.250,90'));
    expect(CurrencyUtils.formatForInput(1250.90), '1.250,90');
  });
}
