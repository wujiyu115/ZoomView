import 'package:flutter/material.dart';
import 'package:zoomview/core/extensions.dart';

class UrlBar extends StatefulWidget {
  final String url;
  final double progress;
  final bool isLoading;
  final ValueChanged<String> onSubmitted;

  const UrlBar({
    super.key,
    required this.url,
    required this.progress,
    required this.isLoading,
    required this.onSubmitted,
  });

  @override
  State<UrlBar> createState() => _UrlBarState();
}

class _UrlBarState extends State<UrlBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.url);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      setState(() => _isEditing = false);
      _controller.text = widget.url;
    }
  }

  @override
  void didUpdateWidget(UrlBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && widget.url != oldWidget.url) {
      _controller.text = widget.url;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          decoration: BoxDecoration(
            color: colors.urlBg,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline, size: 14, color: colors.muted),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: TextStyle(fontSize: 14, color: colors.fg2),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.go,
                  onTap: () => setState(() => _isEditing = true),
                  onSubmitted: (value) {
                    setState(() => _isEditing = false);
                    var url = value.trim();
                    if (!url.startsWith('http://') &&
                        !url.startsWith('https://')) {
                      if (url.contains('.') && !url.contains(' ')) {
                        url = 'https://$url';
                      } else {
                        url =
                            'https://www.google.com/search?q=${Uri.encodeComponent(url)}';
                      }
                    }
                    widget.onSubmitted(url);
                  },
                ),
              ),
              if (widget.isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.accent,
                  ),
                ),
            ],
          ),
        ),
        if (widget.isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(
              value: widget.progress,
              minHeight: 2,
              backgroundColor: Colors.transparent,
              color: colors.accent,
            ),
          ),
      ],
    );
  }
}
