import 'package:flutter/material.dart';

class BrowserToolbar extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onBookmarks;
  final VoidCallback onRefresh;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onMore;
  final VoidCallback onSettings;
  final VoidCallback onTabs;
  final VoidCallback onDownloads;

  const BrowserToolbar({
    super.key,
    required this.onHome,
    required this.onBookmarks,
    required this.onRefresh,
    required this.onBack,
    required this.onForward,
    required this.onMore,
    required this.onSettings,
    required this.onTabs,
    required this.onDownloads,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ToolbarButton(icon: Icons.home_outlined, onTap: onHome),
            _ToolbarButton(icon: Icons.bookmark_outline, onTap: onBookmarks),
            _ToolbarButton(icon: Icons.refresh, onTap: onRefresh),
            _ToolbarButton(
                icon: Icons.arrow_back_ios_new, onTap: onBack, size: 20),
            _ToolbarButton(
                icon: Icons.arrow_forward_ios, onTap: onForward, size: 20),
            _ToolbarButton(icon: Icons.more_horiz, onTap: onMore),
            _ToolbarButton(icon: Icons.settings_outlined, onTap: onSettings),
            _ToolbarButton(icon: Icons.grid_view_rounded, onTap: onTabs),
            _ToolbarButton(icon: Icons.download_outlined, onTap: onDownloads),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _ToolbarButton({
    required this.icon,
    required this.onTap,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: size),
      onPressed: onTap,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}
