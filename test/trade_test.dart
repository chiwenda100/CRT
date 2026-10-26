import 'package:crt_trading_journal/main.dart';
import 'package:crt_trading_journal/trade.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Trade makeTrade({
    required String id,
    required TradeOutcome outcome,
    required double resultR,
    DateTime? date,
  }) {
    return Trade(
      id: id,
      pair: 'EUR/USD',
      direction: TradeDirection.long,
      outcome: outcome,
      session: 'London',
      setup: 'Range sweep',
      date: date ?? DateTime(2026, 10, 20),
      resultR: resultR,
      chartImagePath: '/local/charts/$id.jpg',
    );
  }

  test('stores and reloads trades from local preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await TradeStore.load();
    await store.add(
      makeTrade(id: 'trade-1', outcome: TradeOutcome.win, resultR: 2),
    );

    final reloaded = await TradeStore.load();

    expect(reloaded.trades, hasLength(1));
    expect(reloaded.trades.single.pair, 'EUR/USD');
    expect(reloaded.trades.single.resultR, 2);
    expect(reloaded.trades.single.chartImagePath, '/local/charts/trade-1.jpg');
  });

  test('calculates performance in risk multiples', () {
    final stats = TradeStats([
      makeTrade(id: 'win-1', outcome: TradeOutcome.win, resultR: 2),
      makeTrade(id: 'win-2', outcome: TradeOutcome.win, resultR: 1),
      makeTrade(id: 'loss-1', outcome: TradeOutcome.loss, resultR: -1),
      makeTrade(id: 'be-1', outcome: TradeOutcome.breakeven, resultR: 0),
    ]);

    expect(stats.netR, 2);
    expect(stats.winRate, closeTo(66.67, 0.01));
    expect(stats.averageR, 0.5);
    expect(stats.profitFactor, 3);
  });

  test('keeps newest trades first after persistence', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await TradeStore.load();
    await store.add(
      makeTrade(
        id: 'older',
        outcome: TradeOutcome.win,
        resultR: 1,
        date: DateTime(2026, 10, 1),
      ),
    );
    await store.add(
      makeTrade(
        id: 'newer',
        outcome: TradeOutcome.loss,
        resultR: -1,
        date: DateTime(2026, 10, 2),
      ),
    );

    expect(store.trades.map((trade) => trade.id), ['newer', 'older']);
  });
}
