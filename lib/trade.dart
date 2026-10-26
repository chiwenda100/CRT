import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum TradeDirection { long, short }

enum TradeOutcome { win, loss, breakeven }

class Trade {
  const Trade({
    required this.id,
    required this.pair,
    required this.direction,
    required this.outcome,
    required this.session,
    required this.setup,
    required this.date,
    required this.resultR,
    this.riskPercent,
    this.entry,
    this.stopLoss,
    this.takeProfit,
    this.notes = '',
    this.chartImagePath,
  });

  final String id;
  final String pair;
  final TradeDirection direction;
  final TradeOutcome outcome;
  final String session;
  final String setup;
  final DateTime date;
  final double resultR;
  final double? riskPercent;
  final double? entry;
  final double? stopLoss;
  final double? takeProfit;
  final String notes;
  final String? chartImagePath;

  Map<String, Object?> toJson() => {
    'id': id,
    'pair': pair,
    'direction': direction.name,
    'outcome': outcome.name,
    'session': session,
    'setup': setup,
    'date': date.toIso8601String(),
    'resultR': resultR,
    'riskPercent': riskPercent,
    'entry': entry,
    'stopLoss': stopLoss,
    'takeProfit': takeProfit,
    'notes': notes,
    'chartImagePath': chartImagePath,
  };

  factory Trade.fromJson(Map<String, dynamic> json) => Trade(
    id: json['id'] as String,
    pair: json['pair'] as String,
    direction: TradeDirection.values.byName(json['direction'] as String),
    outcome: TradeOutcome.values.byName(json['outcome'] as String),
    session: json['session'] as String,
    setup: json['setup'] as String,
    date: DateTime.parse(json['date'] as String),
    resultR: (json['resultR'] as num).toDouble(),
    riskPercent: (json['riskPercent'] as num?)?.toDouble(),
    entry: (json['entry'] as num?)?.toDouble(),
    stopLoss: (json['stopLoss'] as num?)?.toDouble(),
    takeProfit: (json['takeProfit'] as num?)?.toDouble(),
    notes: json['notes'] as String? ?? '',
    chartImagePath: json['chartImagePath'] as String?,
  );
}

class TradeStore {
  TradeStore._(this._preferences, this._trades);

  static const _storageKey = 'crt_trading_journal.trades';

  final SharedPreferences _preferences;
  final List<Trade> _trades;

  List<Trade> get trades => List.unmodifiable(_trades);

  static Future<TradeStore> load() async {
    final preferences = await SharedPreferences.getInstance();
    final rawTrades = preferences.getString(_storageKey);
    final trades = rawTrades == null
        ? <Trade>[]
        : (jsonDecode(rawTrades) as List<dynamic>)
              .map((item) => Trade.fromJson(item as Map<String, dynamic>))
              .toList();
    trades.sort((a, b) => b.date.compareTo(a.date));
    return TradeStore._(preferences, trades);
  }

  Future<void> add(Trade trade) async {
    _trades.insert(0, trade);
    try {
      await _save();
    } catch (_) {
      _trades.removeWhere((savedTrade) => savedTrade.id == trade.id);
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    final removed = _trades.where((trade) => trade.id == id).toList();
    _trades.removeWhere((trade) => trade.id == id);
    try {
      await _save();
    } catch (_) {
      _trades.addAll(removed);
      _trades.sort((a, b) => b.date.compareTo(a.date));
      rethrow;
    }
  }

  Future<void> _save() async {
    final saved = await _preferences.setString(
      _storageKey,
      jsonEncode(_trades.map((trade) => trade.toJson()).toList()),
    );
    if (!saved) {
      throw StateError('Could not save trades to this device.');
    }
  }
}
