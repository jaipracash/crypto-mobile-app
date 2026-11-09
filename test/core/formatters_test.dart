import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_research_app/core/utils/formatters.dart';

void main() {
  group('Formatters', () {
    test('formats currency with adaptive decimals', () {
      expect(Formatters.currency(12.345, 'usd'), contains('12.35'));
      expect(Formatters.currency(0.000123456, 'usd'), contains('0.000123'));
      expect(Formatters.currency(null, 'usd'), '—');
    });

    test('formats compact values, signed percentages, and supplies', () {
      expect(Formatters.compact(1200000), contains('1.2M'));
      expect(Formatters.percent(2.5), '+2.50%');
      expect(Formatters.percent(-2.5), '-2.50%');
      expect(Formatters.supply(null), '∞');
      expect(Formatters.supply(1000), '1K');
    });
  });
}
