import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zoomview/core/database/database_helper.dart';
import 'package:zoomview/core/app_colors.dart';
import 'package:zoomview/core/extensions.dart';
import 'package:zoomview/features/history/repositories/history_repository.dart';
import 'package:zoomview/features/history/models/history_model.dart';
import 'package:zoomview/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:zoomview/features/bookmarks/models/bookmark_model.dart';

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
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<_Suggestion> _suggestions = [];
  Timer? _debounce;
  final _historyRepo = HistoryRepository(DatabaseHelper.instance);
  final _bookmarkRepo = BookmarkRepository(DatabaseHelper.instance);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.url);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _debounce?.cancel();
      setState(() => _isEditing = false);
      _controller.text = widget.url;
      _dismissOverlay();
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
    _debounce?.cancel();
    _dismissOverlay();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      _dismissOverlay();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    final results = await Future.wait([
      _historyRepo.search(query),
      _bookmarkRepo.searchBookmarks(query),
    ]);

    final historyItems = (results[0] as List<HistoryModel>)
        .map((h) => _Suggestion(
              title: h.title,
              url: h.url,
              source: _SuggestionSource.history,
            ));

    final bookmarkItems = (results[1] as List<Bookmark>)
        .map((b) => _Suggestion(
              title: b.title,
              url: b.url,
              source: _SuggestionSource.bookmark,
            ));

    final seen = <String>{};
    final merged = <_Suggestion>[];
    for (final item in [...historyItems, ...bookmarkItems]) {
      if (seen.add(item.url) && merged.length < 8) {
        merged.add(item);
      }
    }

    if (!mounted || !_focusNode.hasFocus) return;
    setState(() => _suggestions = merged);

    if (merged.isEmpty) {
      _dismissOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }
    _overlayEntry = OverlayEntry(builder: (_) => _buildOverlay());
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _dismissOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildOverlay() {
    final colors = context.appColors;
    final renderBox = context.findRenderObject() as RenderBox;
    return Positioned(
      width: MediaQuery.of(context).size.width - 32,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: Offset(0, renderBox.size.height),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          color: colors.surfaceElevated,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _suggestions.map((s) => _buildSuggestionTile(s, colors)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(_Suggestion suggestion, AppColors colors) {
    return InkWell(
      onTap: () {
        _dismissOverlay();
        widget.onSubmitted(suggestion.url);
        _focusNode.unfocus();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(
              suggestion.source == _SuggestionSource.history
                  ? Icons.history
                  : Icons.bookmark_outline,
              size: 16,
              color: colors.muted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.title,
                    style: TextStyle(fontSize: 14, color: colors.fg),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    suggestion.url,
                    style: TextStyle(fontSize: 12, color: colors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: Container(
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
                    onTap: () {
                      setState(() => _isEditing = true);
                      if (_controller.text == 'about:blank') {
                        _controller.clear();
                      }
                    },
                    onChanged: _onSearchChanged,
                    onSubmitted: (value) {
                      _dismissOverlay();
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

enum _SuggestionSource { history, bookmark }

class _Suggestion {
  final String title;
  final String url;
  final _SuggestionSource source;

  const _Suggestion({
    required this.title,
    required this.url,
    required this.source,
  });
}
