import 'package:flutter/material.dart';
import 'package:zoomview/core/extensions.dart';
import 'package:zoomview/core/widgets/frosted_container.dart';

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
    return FrostedContainer(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ToolbarButton(icon: Icons.home_outlined, onTap: onHome),
              _ToolbarButton(icon: Icons.bookmark_outline, onTap: onBookmarks),
              _ToolbarButton(icon: Icons.refresh, onTap: onRefresh),
              _ToolbarButton(icon: Icons.arrow_back_ios_new, onTap: onBack, iconSize: 20),
              _ToolbarButton(icon: Icons.arrow_forward_ios, onTap: onForward, iconSize: 20),
              _ToolbarButton(icon: Icons.more_horiz, onTap: onMore),
              _ToolbarButton(icon: Icons.settings_outlined, onTap: onSettings),
              _ToolbarButton(icon: Icons.grid_view_rounded, onTap: onTabs),
              _DownloadButton(onTap: onDownloads, isDownloading: isDownloading),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double iconSize;

  const _ToolbarButton({
    required this.icon,
    required this.onTap,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 36,
        height: 40,
        child: Center(
          child: Icon(icon, size: iconSize, color: colors.fg2),
        ),
      ),
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
    final colors = context.appColors;

    if (!widget.isDownloading) {
      return GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 36,
          height: 40,
          child: Center(
            child: Icon(Icons.download_outlined, size: 22, color: colors.fg2),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 36,
            height: 40,
            child: Center(
              child: Icon(
                Icons.downloading_rounded,
                size: 22,
                color: Color.lerp(colors.fg2, colors.accent, _animation.value),
              ),
            ),
          ),
        );
      },
    );
  }
}
