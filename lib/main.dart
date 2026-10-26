import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'chart_attachment.dart';
import 'trade.dart';

const _background = Color(0xFF0B1118);
const _surface = Color(0xFF121C26);
const _surfaceLight = Color(0xFF1A2733);
const _mint = Color(0xFF55D6A5);
const _muted = Color(0xFF8A9AA8);
const _red = Color(0xFFFF7882);

void main() {
  runApp(const CrtJournalApp());
}

class CrtJournalApp extends StatelessWidget {
  const CrtJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRT Journal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _mint,
          brightness: Brightness.dark,
          surface: _surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _background,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surfaceLight,
          hintStyle: const TextStyle(color: _muted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _mint),
          ),
        ),
      ),
      home: const JournalBootstrap(),
    );
  }
}

class JournalBootstrap extends StatefulWidget {
  const JournalBootstrap({super.key});

  @override
  State<JournalBootstrap> createState() => _JournalBootstrapState();
}

class _JournalBootstrapState extends State<JournalBootstrap> {
  late final Future<TradeStore> _store = TradeStore.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TradeStore>(
      future: _store,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not open your local journal.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: _mint)),
          );
        }
        return JournalHome(store: snapshot.data!);
      },
    );
  }
}

class JournalHome extends StatefulWidget {
  const JournalHome({required this.store, super.key});

  final TradeStore store;

  @override
  State<JournalHome> createState() => _JournalHomeState();
}

class _JournalHomeState extends State<JournalHome> {
  int _tab = 0;

  Future<void> _addTrade() async {
    final trade = await showModalBottomSheet<Trade>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _surface,
      builder: (_) => const TradeFormSheet(),
    );
    if (trade == null || !mounted) return;
    try {
      await widget.store.add(trade);
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) _showMessage('Could not save trade: $error');
    }
  }

  Future<void> _deleteTrade(Trade trade) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this trade?'),
        content: Text('${trade.pair} will be removed from your journal.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await widget.store.delete(trade.id);
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) _showMessage('Could not delete trade: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        trades: widget.store.trades,
        onAddTrade: _addTrade,
        onViewAll: () => setState(() => _tab = 1),
      ),
      TradesPage(trades: widget.store.trades, onDelete: _deleteTrade),
      AnalyticsPage(trades: widget.store.trades),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _tab, children: pages),
      ),
      floatingActionButton: _tab == 1 || _tab == 0
          ? FloatingActionButton.extended(
              onPressed: _addTrade,
              backgroundColor: _mint,
              foregroundColor: _background,
              icon: const Icon(Icons.add),
              label: const Text('Log trade'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        backgroundColor: _surface,
        indicatorColor: _mint.withValues(alpha: .15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Journal',
          ),
          NavigationDestination(
            icon: Icon(Icons.query_stats_outlined),
            selectedIcon: Icon(Icons.query_stats),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.trades,
    required this.onAddTrade,
    required this.onViewAll,
    super.key,
  });

  final List<Trade> trades;
  final VoidCallback onAddTrade;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final stats = TradeStats(trades);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
      children: [
        const _BrandHeader(),
        const SizedBox(height: 26),
        Text('Your edge, measured.', style: _titleStyle),
        const SizedBox(height: 7),
        const Text(
          'A clear view of your CRT trading decisions.',
          style: TextStyle(color: _muted),
        ),
        const SizedBox(height: 22),
        _NetResultCard(stats: stats),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Win rate',
                value: '${stats.winRate.toStringAsFixed(0)}%',
                icon: Icons.track_changes,
                color: _mint,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Trades logged',
                value: '${trades.length}',
                icon: Icons.bar_chart,
                color: const Color(0xFF85A8FF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _SectionHeading(
          title: 'Recent trades',
          actionLabel: trades.isEmpty ? null : 'See all',
          onAction: onViewAll,
        ),
        const SizedBox(height: 12),
        if (trades.isEmpty)
          _EmptyState(onAddTrade: onAddTrade)
        else
          ...trades.take(4).map((trade) => TradeTile(trade: trade)),
      ],
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _mint.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.candlestick_chart, color: _mint),
        ),
        const SizedBox(width: 11),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CRT JOURNAL',
              style: TextStyle(
                fontSize: 13,
                letterSpacing: 2,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Developed by Radon Simba',
              style: TextStyle(color: _muted, fontSize: 9),
            ),
          ],
        ),
        const Spacer(),
        const Icon(Icons.shield_outlined, size: 18, color: _muted),
        const SizedBox(width: 6),
        const Text('Private', style: TextStyle(color: _muted, fontSize: 12)),
      ],
    );
  }
}

class _NetResultCard extends StatelessWidget {
  const _NetResultCard({required this.stats});

  final TradeStats stats;

  @override
  Widget build(BuildContext context) {
    final color = stats.netR >= 0 ? _mint : _red;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF18382F), Color(0xFF14262A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _mint.withValues(alpha: .16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights, size: 18, color: _mint),
              SizedBox(width: 8),
              Text('NET PERFORMANCE', style: _eyebrowStyle),
              Spacer(),
              Text('ALL TIME', style: _eyebrowStyle),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${stats.netR > 0 ? '+' : ''}${stats.netR.toStringAsFixed(2)}R',
            style: TextStyle(
              color: color,
              fontSize: 38,
              height: 1,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${stats.wins} wins  ·  ${stats.losses} losses  ·  ${stats.breakeven} BE',
            style: const TextStyle(color: Color(0xFFB5C9C5), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddTrade});

  final VoidCallback onAddTrade;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .05)),
      ),
      child: Column(
        children: [
          const Icon(Icons.candlestick_chart, color: _mint, size: 34),
          const SizedBox(height: 12),
          const Text(
            'Your journal starts here',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Log your first CRT setup to start measuring your edge.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onAddTrade,
            icon: const Icon(Icons.add),
            label: const Text('Add first trade'),
          ),
        ],
      ),
    );
  }
}

class TradesPage extends StatefulWidget {
  const TradesPage({required this.trades, required this.onDelete, super.key});

  final List<Trade> trades;
  final ValueChanged<Trade> onDelete;

  @override
  State<TradesPage> createState() => _TradesPageState();
}

class _TradesPageState extends State<TradesPage> {
  final _searchController = TextEditingController();
  String _filter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = widget.trades.where((trade) {
      final matchesSearch =
          query.isEmpty ||
          trade.pair.toLowerCase().contains(query) ||
          trade.setup.toLowerCase().contains(query);
      final matchesFilter =
          _filter == 'All' ||
          (_filter == 'Wins' && trade.outcome == TradeOutcome.win) ||
          (_filter == 'Losses' && trade.outcome == TradeOutcome.loss) ||
          (_filter == 'Breakeven' && trade.outcome == TradeOutcome.breakeven);
      return matchesSearch && matchesFilter;
    }).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
      children: [
        const _BrandHeader(),
        const SizedBox(height: 27),
        Text('Trade journal', style: _titleStyle),
        const SizedBox(height: 7),
        Text(
          '${widget.trades.length} trades recorded',
          style: const TextStyle(color: _muted),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Search pair or setup',
            prefixIcon: Icon(Icons.search, color: _muted),
          ),
        ),
        const SizedBox(height: 13),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'Wins', 'Losses', 'Breakeven'].map((filter) {
              final selected = _filter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: selected,
                  onSelected: (_) => setState(() => _filter = filter),
                  selectedColor: _mint.withValues(alpha: .2),
                  labelStyle: TextStyle(
                    color: selected ? _mint : _muted,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: selected
                        ? _mint.withValues(alpha: .5)
                        : _surfaceLight,
                  ),
                  backgroundColor: _surface,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 50),
            child: Text(
              widget.trades.isEmpty
                  ? 'No trades yet. Tap “Log trade” to begin.'
                  : 'No matching trades.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted),
            ),
          )
        else
          ...filtered.map(
            (trade) =>
                TradeTile(trade: trade, onDelete: () => widget.onDelete(trade)),
          ),
      ],
    );
  }
}

class TradeTile extends StatelessWidget {
  const TradeTile({required this.trade, this.onDelete, super.key});

  final Trade trade;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final positive = trade.resultR >= 0;
    final resultColor = trade.resultR == 0
        ? _muted
        : positive
        ? _mint
        : _red;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withValues(alpha: .035)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: resultColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  trade.direction == TradeDirection.long
                      ? Icons.north_east
                      : Icons.south_east,
                  color: resultColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trade.pair,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${trade.setup}  ·  ${_shortDate(trade.date)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${trade.resultR > 0 ? '+' : ''}${trade.resultR.toStringAsFixed(2)}R',
                    style: TextStyle(
                      color: resultColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _outcomeLabel(trade.outcome),
                    style: const TextStyle(color: _muted, fontSize: 10),
                  ),
                ],
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 5),
                IconButton(
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Delete trade',
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 19,
                    color: _muted,
                  ),
                ),
              ],
            ],
          ),
          if (trade.chartImagePath case final imagePath?) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ChartAttachmentImage(
                imagePath: imagePath,
                height: 150,
                width: double.infinity,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({required this.trades, super.key});

  final List<Trade> trades;

  @override
  Widget build(BuildContext context) {
    final stats = TradeStats(trades);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        const _BrandHeader(),
        const SizedBox(height: 27),
        Text('Performance', style: _titleStyle),
        const SizedBox(height: 7),
        const Text(
          'Review your results in risk multiples.',
          style: TextStyle(color: _muted),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CUMULATIVE R', style: _eyebrowStyle),
              const SizedBox(height: 22),
              SizedBox(
                height: 155,
                width: double.infinity,
                child: trades.isEmpty
                    ? const Center(
                        child: Text(
                          'Log trades to see your equity curve.',
                          style: TextStyle(color: _muted),
                        ),
                      )
                    : CustomPaint(
                        painter: _EquityCurvePainter(trades.reversed.toList()),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Average result',
                value:
                    '${stats.averageR > 0 ? '+' : ''}${stats.averageR.toStringAsFixed(2)}R',
                icon: Icons.functions,
                color: const Color(0xFF85A8FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Profit factor',
                value: stats.profitFactorLabel,
                icon: Icons.balance,
                color: _mint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('OUTCOME BREAKDOWN', style: _eyebrowStyle),
              const SizedBox(height: 18),
              _BreakdownRow(
                label: 'Wins',
                value: stats.wins,
                total: trades.length,
                color: _mint,
              ),
              const SizedBox(height: 14),
              _BreakdownRow(
                label: 'Losses',
                value: stats.losses,
                total: trades.length,
                color: _red,
              ),
              const SizedBox(height: 14),
              _BreakdownRow(
                label: 'Breakeven',
                value: stats.breakeven,
                total: trades.length,
                color: const Color(0xFF85A8FF),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: _surfaceLight.withValues(alpha: .55),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: _muted, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Keep your risk consistent. Past performance does not predict future results.',
                  style: TextStyle(color: _muted, fontSize: 12, height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : value / total;
    return Row(
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 7,
              backgroundColor: _surfaceLight,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 30,
          child: Text(
            '$value',
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _EquityCurvePainter extends CustomPainter {
  const _EquityCurvePainter(this.trades);

  final List<Trade> trades;

  @override
  void paint(Canvas canvas, Size size) {
    final values = <double>[0];
    for (final trade in trades) {
      values.add(values.last + trade.resultR);
    }
    var low = values.reduce((a, b) => a < b ? a : b);
    var high = values.reduce((a, b) => a > b ? a : b);
    if (low == high) {
      low -= 1;
      high += 1;
    }
    final range = high - low;
    final chartHeight = size.height - 12;
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? 0.0 : i * size.width / (values.length - 1);
      final y = chartHeight - (values[i] - low) / range * chartHeight + 6;
      points.add(Offset(x, y));
    }
    final zeroY = chartHeight - (0 - low) / range * chartHeight + 6;
    canvas.drawLine(
      Offset(0, zeroY),
      Offset(size.width, zeroY),
      Paint()
        ..color = Colors.white.withValues(alpha: .12)
        ..strokeWidth = 1,
    );
    if (points.length == 1) {
      canvas.drawCircle(points.first, 4, Paint()..color = _mint);
      return;
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = values.last >= 0 ? _mint : _red
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    for (final point in points.skip(1)) {
      canvas.drawCircle(
        point,
        3,
        Paint()..color = values.last >= 0 ? _mint : _red,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EquityCurvePainter oldDelegate) =>
      oldDelegate.trades != trades;
}

class TradeFormSheet extends StatefulWidget {
  const TradeFormSheet({super.key});

  @override
  State<TradeFormSheet> createState() => _TradeFormSheetState();
}

class _TradeFormSheetState extends State<TradeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _pairController = TextEditingController(text: 'EUR/USD');
  final _resultController = TextEditingController();
  final _riskController = TextEditingController();
  final _entryController = TextEditingController();
  final _stopController = TextEditingController();
  final _targetController = TextEditingController();
  final _notesController = TextEditingController();
  final _imagePicker = ImagePicker();
  XFile? _selectedChart;
  TradeDirection _direction = TradeDirection.long;
  TradeOutcome _outcome = TradeOutcome.win;
  String _session = 'London';
  String _setup = 'Range sweep';
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _pairController.dispose();
    _resultController.dispose();
    _riskController.dispose();
    _entryController.dispose();
    _stopController.dispose();
    _targetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double? _optionalNumber(String text) =>
      text.trim().isEmpty ? null : double.tryParse(text.trim());

  String? _numberValidator(String? value, {required bool required}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Enter a result in R' : null;
    }
    return double.tryParse(value.trim()) == null
        ? 'Enter a valid number'
        : null;
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date != null) setState(() => _date = date);
  }

  Future<void> _pickChartImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 2200,
      );
      if (image != null && mounted) {
        setState(() => _selectedChart = image);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not select chart screenshot: $error')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final result = double.parse(_resultController.text.trim());
    if ((_outcome == TradeOutcome.win && result <= 0) ||
        (_outcome == TradeOutcome.loss && result >= 0) ||
        (_outcome == TradeOutcome.breakeven && result != 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (_outcome) {
            TradeOutcome.win => 'A win should have a positive R result.',
            TradeOutcome.loss => 'A loss should have a negative R result.',
            TradeOutcome.breakeven => 'A breakeven result should be 0R.',
          }),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    String? chartImagePath;
    try {
      if (_selectedChart != null) {
        chartImagePath = await saveChartImage(_selectedChart!, id);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save chart screenshot: $error')),
        );
      }
      return;
    }
    if (!mounted) return;
    Navigator.pop(
      context,
      Trade(
        id: id,
        pair: _pairController.text.trim().toUpperCase(),
        direction: _direction,
        outcome: _outcome,
        session: _session,
        setup: _setup,
        date: _date,
        resultR: result,
        riskPercent: _optionalNumber(_riskController.text),
        entry: _optionalNumber(_entryController.text),
        stopLoss: _optionalNumber(_stopController.text),
        takeProfit: _optionalNumber(_targetController.text),
        notes: _notesController.text.trim(),
        chartImagePath: chartImagePath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .92,
        minChildSize: .65,
        maxChildSize: .96,
        builder: (context, scrollController) => Form(
          key: _formKey,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _muted.withValues(alpha: .4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Text('Log a trade', style: _titleStyle)),
                  TextButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_shortDate(_date)),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              const _FieldLabel('MARKET'),
              const SizedBox(height: 7),
              TextFormField(
                controller: _pairController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(hintText: 'EUR/USD'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a pair'
                    : null,
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _ChoiceField<TradeDirection>(
                      label: 'DIRECTION',
                      value: _direction,
                      options: const {
                        TradeDirection.long: 'Long',
                        TradeDirection.short: 'Short',
                      },
                      onChanged: (value) => setState(() => _direction = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ChoiceField<TradeOutcome>(
                      label: 'OUTCOME',
                      value: _outcome,
                      options: const {
                        TradeOutcome.win: 'Win',
                        TradeOutcome.loss: 'Loss',
                        TradeOutcome.breakeven: 'Breakeven',
                      },
                      onChanged: (value) => setState(() => _outcome = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _ChoiceField<String>(
                      label: 'SESSION',
                      value: _session,
                      options: const {
                        'Asia': 'Asia',
                        'London': 'London',
                        'New York': 'New York',
                        'Other': 'Other',
                      },
                      onChanged: (value) => setState(() => _session = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ChoiceField<String>(
                      label: 'CRT SETUP',
                      value: _setup,
                      options: const {
                        'Range sweep': 'Range sweep',
                        'Candle range': 'Candle range',
                        'Reversal': 'Reversal',
                        'Other': 'Other',
                      },
                      onChanged: (value) => setState(() => _setup = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const _FieldLabel('RESULT (R MULTIPLE)'),
              const SizedBox(height: 7),
              TextFormField(
                controller: _resultController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  hintText: _outcome == TradeOutcome.win
                      ? 'e.g. 2.0'
                      : _outcome == TradeOutcome.loss
                      ? 'e.g. -1.0'
                      : '0',
                  suffixText: 'R',
                ),
                validator: (value) => _numberValidator(value, required: true),
              ),
              const SizedBox(height: 15),
              const _FieldLabel('RISK & PRICE LEVELS (OPTIONAL)'),
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(
                    child: _numberField(_riskController, 'Risk %', suffix: '%'),
                  ),
                  const SizedBox(width: 9),
                  Expanded(child: _numberField(_entryController, 'Entry')),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(child: _numberField(_stopController, 'Stop loss')),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _numberField(_targetController, 'Take profit'),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const _FieldLabel('NOTES'),
              const SizedBox(height: 7),
              TextFormField(
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'What did you see? How was the execution?',
                ),
              ),
              const SizedBox(height: 15),
              const _FieldLabel('CHART SCREENSHOT (OPTIONAL)'),
              const SizedBox(height: 7),
              if (_selectedChart != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: FutureBuilder(
                    future: _selectedChart!.readAsBytes(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox(
                          height: 170,
                          child: Center(
                            child: CircularProgressIndicator(color: _mint),
                          ),
                        );
                      }
                      return Image.memory(
                        snapshot.data!,
                        height: 170,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: _saving ? null : _pickChartImage,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(
                  _selectedChart == null
                      ? 'Choose screenshot from gallery'
                      : 'Change screenshot',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _mint,
                    foregroundColor: _background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Save trade',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String hint, {
    String? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: InputDecoration(hintText: hint, suffixText: suffix),
      validator: (value) => _numberValidator(value, required: false),
    );
  }
}

class _ChoiceField<T> extends StatelessWidget {
  const _ChoiceField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 7),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12),
          ),
          items: options.entries
              .map(
                (entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: _muted,
      fontSize: 10,
      letterSpacing: 1,
      fontWeight: FontWeight.w700,
    ),
  );
}

class TradeStats {
  TradeStats(this.trades);

  final List<Trade> trades;

  int get wins =>
      trades.where((trade) => trade.outcome == TradeOutcome.win).length;
  int get losses =>
      trades.where((trade) => trade.outcome == TradeOutcome.loss).length;
  int get breakeven =>
      trades.where((trade) => trade.outcome == TradeOutcome.breakeven).length;
  double get netR => trades.fold(0, (sum, trade) => sum + trade.resultR);
  double get winRate {
    final decisiveTrades = wins + losses;
    return decisiveTrades == 0 ? 0 : wins / decisiveTrades * 100;
  }

  double get averageR => trades.isEmpty ? 0 : netR / trades.length;

  double get profitFactor {
    final grossWins = trades
        .where((trade) => trade.resultR > 0)
        .fold<double>(0, (sum, trade) => sum + trade.resultR);
    final grossLosses = trades
        .where((trade) => trade.resultR < 0)
        .fold<double>(0, (sum, trade) => sum + trade.resultR.abs());
    if (grossLosses == 0) return grossWins > 0 ? double.infinity : 0;
    return grossWins / grossLosses;
  }

  String get profitFactorLabel =>
      profitFactor.isInfinite ? '∞' : profitFactor.toStringAsFixed(2);
}

const _titleStyle = TextStyle(
  fontSize: 26,
  fontWeight: FontWeight.w700,
  letterSpacing: -.5,
);
const _eyebrowStyle = TextStyle(
  color: Color(0xFFB5C9C5),
  fontSize: 10,
  letterSpacing: 1.2,
  fontWeight: FontWeight.w700,
);

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!, style: const TextStyle(color: _mint)),
          ),
      ],
    );
  }
}

String _outcomeLabel(TradeOutcome outcome) => switch (outcome) {
  TradeOutcome.win => 'WIN',
  TradeOutcome.loss => 'LOSS',
  TradeOutcome.breakeven => 'BREAKEVEN',
};

String _shortDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}';

String _month(int month) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][month - 1];
