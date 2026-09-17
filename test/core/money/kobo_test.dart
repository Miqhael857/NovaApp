import 'package:flutter_test/flutter_test.dart';

import 'package:novawallet/core/money/kobo.dart';

void main() {
  group('format', () {
    test('formats the amounts shown in the design', () {
      expect(Kobo.zero.format(), '₦0.00');
      expect(const Kobo(1).format(), '₦0.01');
      expect(const Kobo(99).format(), '₦0.99');
      expect(const Kobo(100).format(), '₦1.00');
      expect(const Kobo(1234567).format(), '₦12,345.67');
      expect(const Kobo(24835075).format(), '₦248,350.75');
      expect(const Kobo(32000000).format(), '₦320,000.00');
    });

    test('groups thousands at every scale', () {
      expect(const Kobo(99900).format(), '₦999.00');
      expect(const Kobo(100000).format(), '₦1,000.00');
      expect(const Kobo(99999999999).format(), '₦999,999,999.99');
    });

    test('shows the sign in front of the symbol', () {
      expect(const Kobo(-1500000).format(), '-₦15,000.00');
      expect(const Kobo(-1).format(), '-₦0.01');
    });

    test('can drop the symbol for input fields', () {
      expect(const Kobo(24835075).format(symbol: false), '248,350.75');
    });
  });

  group('tryParse', () {
    test('reads what a user might type', () {
      expect(Kobo.tryParse('0'), Kobo.zero);
      expect(Kobo.tryParse('0.01'), const Kobo(1));
      expect(Kobo.tryParse('1000'), const Kobo(100000));
      expect(Kobo.tryParse('12,500.5'), const Kobo(1250050));
      expect(Kobo.tryParse('₦12,500.50'), const Kobo(1250050));
      expect(Kobo.tryParse('  1,000.00  '), const Kobo(100000));
    });

    test('rejects anything that is not a plain positive amount', () {
      expect(Kobo.tryParse(''), isNull);
      expect(Kobo.tryParse('   '), isNull);
      expect(Kobo.tryParse('abc'), isNull);
      expect(Kobo.tryParse('1.234'), isNull, reason: 'more than 2 decimals');
      expect(Kobo.tryParse('1.2.3'), isNull, reason: 'two decimal points');
      expect(Kobo.tryParse('-5'), isNull, reason: 'no negative input');
      expect(Kobo.tryParse('.50'), isNull, reason: 'missing whole part');
      expect(Kobo.tryParse('1e3'), isNull);
    });

    test('parse throws where tryParse returns null', () {
      expect(() => Kobo.parse('abc'), throwsFormatException);
      expect(Kobo.parse('₦7,500.00'), const Kobo(750000));
    });

    test('round-trips through format and back', () {
      const amounts = [
        Kobo.zero,
        Kobo(1),
        Kobo(750000),
        Kobo(24835075),
        Kobo(99999999999),
      ];
      for (final amount in amounts) {
        expect(Kobo.tryParse(amount.format()), amount);
      }
    });
  });

  group('arithmetic stays exact', () {
    test('the classic 0.1 + 0.2 case', () {
      // 0.1 + 0.2 == 0.30000000000000004 in doubles. Not here.
      final sum = const Kobo(10) + const Kobo(20);
      expect(sum, const Kobo(30));
      expect(sum.format(), '₦0.30');
    });

    test('adding one kobo a thousand times lands exactly on ₦10.00', () {
      var total = Kobo.zero;
      for (var i = 0; i < 1000; i++) {
        total += const Kobo(1);
      }
      expect(total, const Kobo(1000));
      expect(total.format(), '₦10.00');
    });

    test('subtraction can go negative for a pending balance', () {
      final available = const Kobo(24835075) - const Kobo(25000000);
      expect(available.isNegative, isTrue);
      expect(available.format(), '-₦1,649.25');
    });

    test('multiplies by a whole number', () {
      expect(const Kobo(150000) * 3, const Kobo(450000));
    });
  });

  group('percentOf', () {
    test('matches the goal progress in the design', () {
      // Rent 2027: ₦285,000 of ₦600,000 is 47.5%, shown as 47%.
      expect(const Kobo(28500000).percentOf(const Kobo(60000000)), 47);
      // New laptop: ₦97,500 of ₦450,000 is 21.67%, shown as 21%.
      expect(const Kobo(9750000).percentOf(const Kobo(45000000)), 21);
      expect(const Kobo(3000000).percentOf(const Kobo(20000000)), 15);
    });

    test('never exceeds 100 or drops below 0', () {
      expect(const Kobo(20000).percentOf(const Kobo(10000)), 100);
      expect(const Kobo(-500).percentOf(const Kobo(10000)), 0);
    });

    test('handles a zero or missing target without dividing by zero', () {
      expect(const Kobo(5000).percentOf(Kobo.zero), 0);
    });
  });

  group('value semantics', () {
    test('two amounts with the same value are equal', () {
      expect(const Kobo(1500), const Kobo(1500));
      expect(const Kobo(1500).hashCode, const Kobo(1500).hashCode);
      expect(const Kobo(1500) == const Kobo(1501), isFalse);
    });

    test('compares and sorts', () {
      expect(const Kobo(100) < const Kobo(200), isTrue);
      expect(const Kobo(200) >= const Kobo(200), isTrue);

      final amounts = [const Kobo(300), const Kobo(100), const Kobo(200)]
        ..sort();
      expect(amounts, const [Kobo(100), Kobo(200), Kobo(300)]);
    });

    test('fromNaira builds the right value', () {
      expect(Kobo.fromNaira(1250, 50), const Kobo(125050));
      expect(Kobo.fromNaira(15000), const Kobo(1500000));
    });

    test('toString is the formatted amount', () {
      expect('${const Kobo(24835075)}', '₦248,350.75');
    });
  });
}
