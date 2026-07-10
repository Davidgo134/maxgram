
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../models_chat.dart';
import '../theme/maxgram_theme.dart';
import '../widgets/maxgram_chat_row.dart';
import '../max_protocol/max_repository.dart';
import 'maxgram_chat_screen.dart';

/// Maxgram chat list screen — now backed by live MaxRepository data
/// instead of a static demo list. Subscribes to chatsStream for
/// real-time updates as new messages arrive over the MAX WebSocket.
class MaxgramChatListScreen extends StatefulWidget {
  final MaxRepository repository;

  const MaxgramChatListScreen({super.key, required this.repository});

  @override
  State<MaxgramChatListScreen> createState() => _MaxgramChatListScreenState();
}

class _MaxgramChatListScreenState extends State<MaxgramChatListScreen> {
  List<MaxgramChat> _chats = [];
  StreamSubscription? _subscription;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subscription = widget.repository.chatsStream.listen((chats) {
      setState(() => _chats = _sorted(chats));
    });
    _loadInitial();
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
  }

  List<MaxgramChat> _sorted(List<MaxgramChat> chats) {
    final sorted = List.of(chats);
    sorted.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.timestamp.compareTo(a.timestamp);
    });
    return sorted;
  }

  Future<void> _loadInitial() async {
    setState(() { _loading = true; _error = null; });
    try {
      final chats = await widget.repository.loadChats();
      setState(() => _chats = _sorted(chats));
    } catch (e) {
      setState(() => _error = 'Не удалось загрузить чаты: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collapseProgress = (_scrollOffset / 44).clamp(0.0, 1.0);
    final titleSize = _lerp(34, 17, collapseProgress);

    return CupertinoPageScaffold(
      backgroundColor: MaxgramColors.background,
      child: SafeArea(
        child: Column(
          children: [
            _buildNavBar(collapseProgress, titleSize),
            _buildSearchBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: TextStyle(color: MaxgramColors.swipeDelete), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              CupertinoButton(onPressed: _loadInitial, child: const Text('Повторить')),
            ],
          ),
        ),
      );
    }
    if (_chats.isEmpty) {
      return Center(child: Text('Нет чатов', style: TextStyle(color: MaxgramColors.subtitleText)));
    }
    return ListView.separated(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: _chats.length,
      separatorBuilder: (_, __) => Divider(height: 1, indent: 80, color: MaxgramColors.separator),
      itemBuilder: (context, index) {
        final chat = _chats[index];
        return MaxgramChatRow(
          chat: chat,
          onTap: () {
            Navigator.of(context).push(CupertinoPageRoute(
              builder: (_) => MaxgramChatScreen(
                chatId: chat.id,
                chatTitle: chat.title,
                repository: widget.repository,
              ),
            ));
          },
          onArchive: () {},
          onDelete: () {},
          onMuteToggle: () {},
        );
      },
    );
  }

  Widget _buildNavBar(double collapseProgress, double titleSize) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: MaxgramCurves.navBarCollapse,
      height: _lerp(96, 44, collapseProgress),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.bottomLeft,
      decoration: BoxDecoration(
        color: MaxgramColors.background.withOpacity(0.94),
        border: collapseProgress > 0.5
            ? Border(bottom: BorderSide(color: MaxgramColors.separator, width: 0.5))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text('Maxgram', style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w700, color: MaxgramColors.titleText)),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        height: 36,
        decoration: BoxDecoration(color: MaxgramColors.secondaryBackground, borderRadius: BorderRadius.circular(10)),
        child: const Row(
          children: [
            SizedBox(width: 8),
            Icon(Icons.search, size: 18, color: MaxgramColors.subtitleText),
            SizedBox(width: 6),
            Text('Search', style: TextStyle(color: MaxgramColors.subtitleText, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  double _lerp(num a, num b, double t) => a + (b - a) * t;
}
