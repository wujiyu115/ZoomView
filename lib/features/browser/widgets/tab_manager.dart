import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoomview/features/browser/providers/browser_provider.dart';
import 'package:zoomview/core/constants.dart';

class TabManager extends ConsumerWidget {
  const TabManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final browserState = ref.watch(browserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Tabs (${browserState.tabs.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ref.read(browserProvider.notifier).addTab(AppConstants.defaultHomeUrl);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.75,
        ),
        itemCount: browserState.tabs.length,
        itemBuilder: (context, index) {
          final tab = browserState.tabs[index];
          final isActive = index == browserState.activeTabIndex;

          return GestureDetector(
            onTap: () {
              ref.read(browserProvider.notifier).switchTab(index);
              Navigator.pop(context);
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isActive ? Colors.blue : Colors.grey[700]!,
                  width: isActive ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[900],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(11),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            tab.title.isEmpty ? 'New Tab' : tab.title,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            ref.read(browserProvider.notifier).closeTab(index);
                          },
                          child: const Icon(Icons.close, size: 16),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          tab.url,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
