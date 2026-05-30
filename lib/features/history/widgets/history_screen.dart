import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoomview/core/extensions.dart';
import 'package:zoomview/core/widgets/ios_nav_header.dart';
import 'package:zoomview/core/widgets/grouped_card.dart';
import 'package:zoomview/core/widgets/colored_icon_box.dart';
import 'package:zoomview/core/widgets/search_bar_widget.dart';
import 'package:zoomview/core/widgets/section_header.dart';
import 'package:zoomview/l10n/app_localizations.dart';
import '../models/history_model.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(historyProvider.notifier).load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(historyProvider);
    final colors = context.appColors;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            IosNavHeader(
              title: l.history,
              trailing: entries.isEmpty
                  ? null
                  : GestureDetector(
                      onTap: () => _showClearDialog(context),
                      child: Text(
                        l.clear,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: colors.danger,
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SearchBarWidget(
                hint: l.searchHistory,
                controller: _searchController,
                onChanged: (query) {
                  ref.read(historyProvider.notifier).search(query);
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Text(l.noHistoryEntries, style: TextStyle(color: colors.muted)),
                    )
                  : _buildGroupedList(entries),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedList(List<HistoryModel> entries) {
    final l = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayEntries = <HistoryModel>[];
    final yesterdayEntries = <HistoryModel>[];
    final earlierEntries = <HistoryModel>[];

    for (final entry in entries) {
      final entryDate = DateTime(
        entry.visitedAt.year,
        entry.visitedAt.month,
        entry.visitedAt.day,
      );
      if (entryDate == today) {
        todayEntries.add(entry);
      } else if (entryDate == yesterday) {
        yesterdayEntries.add(entry);
      } else {
        earlierEntries.add(entry);
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (todayEntries.isNotEmpty) ...[
          SectionHeader(label: l.today),
          _buildGroup(todayEntries),
        ],
        if (yesterdayEntries.isNotEmpty) ...[
          SectionHeader(label: l.yesterday),
          _buildGroup(yesterdayEntries),
        ],
        if (earlierEntries.isNotEmpty) ...[
          SectionHeader(label: l.earlier),
          _buildGroup(earlierEntries),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGroup(List<HistoryModel> entries) {
    return GroupedCard(
      children: entries.map((entry) => _buildEntryItem(entry)).toList(),
    );
  }

  Widget _buildEntryItem(HistoryModel entry) {
    final colors = context.appColors;
    final domain = Uri.tryParse(entry.url)?.host ?? entry.url;
    final letter = entry.title.isNotEmpty
        ? entry.title[0].toUpperCase()
        : domain.isNotEmpty
            ? domain[0].toUpperCase()
            : '?';
    final timeStr =
        '${entry.visitedAt.hour.toString().padLeft(2, '0')}:${entry.visitedAt.minute.toString().padLeft(2, '0')}';

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: colors.danger,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(historyProvider.notifier).deleteEntry(entry.id!);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context, entry.url),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              ColoredIconBox(
                color: colors.urlBg,
                letter: letter,
                size: 36,
                borderRadius: 10,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title.isNotEmpty ? entry.title : domain,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: colors.fg,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      domain,
                      style: TextStyle(fontSize: 12, color: colors.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.muted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.clearHistory),
        content: Text(l.clearHistoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () {
              ref.read(historyProvider.notifier).clearAll();
              Navigator.pop(ctx);
            },
            child: Text(l.clear, style: TextStyle(color: context.appColors.danger)),
          ),
        ],
      ),
    );
  }
}
