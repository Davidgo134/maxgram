
import 'package:flutter/material.dart';
import '../theme/maxgram_theme.dart';

/// Unread counter / mute icon badge, mirrors Telegram-iOS
/// ChatListBadgeNode behaviour (green = unread, grey = muted).
class MaxgramBadge extends StatelessWidget {
  final int count;
  final bool isMuted;

  const MaxgramBadge({super.key, required this.count, this.isMuted = false});

  @override
  Widget build(BuildContext context) {
    if (count <= 0 && !isMuted) return const SizedBox.shrink();

    final bg = isMuted ? MaxgramColors.mutedBadge : MaxgramColors.unreadBadge;

    if (isMuted && count <= 0) {
      return Icon(Icons.volume_off, size: 18, color: MaxgramColors.mutedBadge);
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
      alignment: Alignment.center,
      child: Text(
        count > 999 ? '999+' : '$count',
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
