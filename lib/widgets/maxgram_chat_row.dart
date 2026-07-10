
import 'package:flutter/material.dart';
import '../models_chat.dart';
import '../theme/maxgram_theme.dart';
import 'maxgram_avatar.dart';
import 'maxgram_badge.dart';

/// Single chat row with elastic swipe-to-reveal actions,
/// mirroring Telegram-iOS ItemListRevealOptionsNode behaviour:
/// swipe left reveals Archive/Mute/Delete, with an elastic
/// overscroll snap-back if the drag doesn't cross threshold.
class MaxgramChatRow extends StatefulWidget {
  final MaxgramChat chat;
  final VoidCallback? onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onMuteToggle;

  const MaxgramChatRow({
    super.key,
    required this.chat,
    this.onTap,
    this.onArchive,
    this.onDelete,
    this.onMuteToggle,
  });

  @override
  State<MaxgramChatRow> createState() => _MaxgramChatRowState();
}

class _MaxgramChatRowState extends State<MaxgramChatRow>
    with SingleTickerProviderStateMixin {
  double _dragExtent = 0;
  static const double _actionWidth = 74;
  static const double _maxReveal = _actionWidth * 3;
  late final AnimationController _snapController;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _snapTo(double target) {
    final animation = Tween<double>(begin: _dragExtent, end: target).animate(
      CurvedAnimation(parent: _snapController, curve: MaxgramCurves.swipeElastic),
    );
    animation.addListener(() => setState(() => _dragExtent = animation.value));
    _snapController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragExtent = (_dragExtent - details.delta.dx).clamp(0.0, _maxReveal);
        });
      },
      onHorizontalDragEnd: (details) {
        if (_dragExtent > _maxReveal * 0.35) {
          _snapTo(_maxReveal);
        } else {
          _snapTo(0);
        }
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: Row(
              children: [
                const Spacer(),
                _actionButton('Archive', MaxgramColors.swipeArchive, Icons.archive, widget.onArchive),
                _actionButton(chat.isMuted ? 'Unmute' : 'Mute', MaxgramColors.swipeMute, Icons.notifications_off, widget.onMuteToggle),
                _actionButton('Delete', MaxgramColors.swipeDelete, Icons.delete, widget.onDelete),
              ],
            ),
          ),
          Transform.translate(
            offset: Offset(-_dragExtent, 0),
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                color: MaxgramColors.background,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    MaxgramAvatar(
                      letter: chat.avatarLetter ?? (chat.title.isNotEmpty ? chat.title[0] : '?'),
                      colorIndex: chat.avatarColorIndex,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chat.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: MaxgramColors.titleText,
                                  ),
                                ),
                              ),
                              Text(
                                _formatTime(chat.timestamp),
                                style: TextStyle(fontSize: 13, color: MaxgramColors.subtitleText),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chat.lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 15, color: MaxgramColors.subtitleText),
                                ),
                              ),
                              const SizedBox(width: 6),
                              MaxgramBadge(count: chat.unreadCount, isMuted: chat.isMuted),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, Color color, IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: () {
        onTap?.call();
        _snapTo(0);
      },
      child: Container(
        width: _actionWidth,
        color: color,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    if (t.year == now.year && t.month == now.month && t.day == now.day) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    return '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year.toString().substring(2)}';
  }
}
