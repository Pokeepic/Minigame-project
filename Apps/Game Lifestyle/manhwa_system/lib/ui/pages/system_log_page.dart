import 'package:flutter/material.dart';
import '../../services/system_controller.dart';
import '../../services/system_events.dart';
import '../../models/system_log.dart';

class SystemLogPage extends StatefulWidget {
  final SystemController controller;
  const SystemLogPage({super.key, required this.controller});

  @override
  State<SystemLogPage> createState() => _SystemLogPageState();
}

class _SystemLogPageState extends State<SystemLogPage> {
  LogType? filter; // null = ALL
  String query = '';

  IconData _iconFor(LogType type) {
    switch (type) {
      case LogType.quest:
        return Icons.task_alt;
      case LogType.bonus:
        return Icons.card_giftcard;
      case LogType.upgrade:
        return Icons.upgrade;
      case LogType.level:
        return Icons.trending_up;
      case LogType.streak:
        return Icons.local_fire_department;
      case LogType.milestone:
        return Icons.emoji_events;
      case LogType.title:
        return Icons.badge;
      case LogType.info:
        return Icons.info_outline;
    }
  }

  String _dayKey(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  String _time(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.controller.systemLog;

    final filtered = all.where((e) {
      final okType = filter == null || e.type == filter;
      final okQuery = query.isEmpty ||
          e.message.toLowerCase().contains(query.toLowerCase());
      return okType && okQuery;
    }).toList();

    // group by day
    final Map<String, List<SystemLogEntry>> grouped = {};
    for (final e in filtered) {
      final key = _dayKey(DateTime.fromMillisecondsSinceEpoch(e.ts));
      grouped.putIfAbsent(key, () => []).add(e);
    }
    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('SYSTEM LOG'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip(null, 'ALL'),
                  ...LogType.values.map((t) => _chip(t, t.name.toUpperCase())),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // search
            TextField(
              onChanged: (v) => setState(() => query = v.trim()),
              decoration: InputDecoration(
                hintText: 'Search system log…',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),

            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No logs found.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: days.length,
                      itemBuilder: (context, i) {
                        final day = days[i];
                        final items = grouped[day]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              day,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...items.map((e) => _card(e)),
                            const SizedBox(height: 18),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(LogType? type, String label) {
    final selected = filter == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        label: Text(label),
        onSelected: (_) => setState(() => filter = type),
      ),
    );
  }

  Widget _card(SystemLogEntry e) {
    final accent = Color(LogType.getColorForType(e.type));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
        color: Colors.black.withValues(alpha: 0.10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_iconFor(e.type), color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _time(e.ts),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  e.message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
