import 'package:flutter/material.dart';

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
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.url);
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(Icons.lock_outline, size: 16, color: Colors.grey),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
        if (widget.isLoading)
          LinearProgressIndicator(
            value: widget.progress,
            minHeight: 2,
          ),
      ],
    );
  }
}
