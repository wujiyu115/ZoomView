import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.history),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: entries.isEmpty ? null : () => _showClearDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l.searchHistory,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(historyProvider.notifier).search('');
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (query) {
                ref.read(historyProvider.notifier).search(query);
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? Center(child: Text(l.noHistoryEntries))
                : _buildGroupedList(entries),
          ),
        ],
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
      children: [
        if (todayEntries.isNotEmpty) ...[
          _buildSectionHeader(l.today),
          ...todayEntries.map(_buildEntryTile),
        ],
        if (yesterdayEntries.isNotEmpty) ...[
          _buildSectionHeader(l.yesterday),
          ...yesterdayEntries.map(_buildEntryTile),
        ],
        if (earlierEntries.isNotEmpty) ...[
          _buildSectionHeader(l.earlier),
          ...earlierEntries.map(_buildEntryTile),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildEntryTile(HistoryModel entry) {
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(historyProvider.notifier).deleteEntry(entry.id!);
      },
      child: ListTile(
        leading: const Icon(Icons.history),
        title: Text(
          entry.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          entry.url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => Navigator.pop(context, entry.url),
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
            child: Text(l.clear),
          ),
        ],
      ),
    );
  }
}
