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
  final bool isDownloading;

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
    this.isDownloading = false,
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
            Flexible(child: _ToolbarButton(icon: Icons.home_outlined, onTap: onHome)),
            Flexible(child: _ToolbarButton(icon: Icons.bookmark_outline, onTap: onBookmarks)),
            Flexible(child: _ToolbarButton(icon: Icons.refresh, onTap: onRefresh)),
            Flexible(child: _ToolbarButton(
                icon: Icons.arrow_back_ios_new, onTap: onBack, size: 20)),
            Flexible(child: _ToolbarButton(
                icon: Icons.arrow_forward_ios, onTap: onForward, size: 20)),
            Flexible(child: _ToolbarButton(icon: Icons.more_horiz, onTap: onMore)),
            Flexible(child: _ToolbarButton(icon: Icons.settings_outlined, onTap: onSettings)),
            Flexible(child: _ToolbarButton(icon: Icons.grid_view_rounded, onTap: onTabs)),
            Flexible(child: _DownloadButton(onTap: onDownloads, isDownloading: isDownloading)),
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
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 36),
    );
  }
}

class _DownloadButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isDownloading;

  const _DownloadButton({required this.onTap, required this.isDownloading});

  @override
  State<_DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<_DownloadButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isDownloading) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _DownloadButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDownloading && !oldWidget.isDownloading) {
      _controller.repeat(reverse: true);
    } else if (!widget.isDownloading && oldWidget.isDownloading) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isDownloading) {
      return IconButton(
        icon: const Icon(Icons.download_outlined, size: 24),
        onPressed: widget.onTap,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 36),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return IconButton(
          icon: Icon(
            Icons.downloading_rounded,
            size: 24,
            color: Color.lerp(
              Theme.of(context).iconTheme.color,
              Colors.blue,
              _animation.value,
            ),
          ),
          onPressed: widget.onTap,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 36),
        );
      },
    );
  }
}
