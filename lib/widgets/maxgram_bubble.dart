
import 'package:flutter/material.dart';
import '../models_message.dart';
import '../theme/maxgram_theme.dart';

/// Message bubble mirroring Telegram-iOS ChatMessageBubbleItemNode:
/// - grouped messages from same sender get "smooth" corners
/// - only the LAST message in a consecutive group renders a tail
/// - outgoing bubbles: blue gradient, right-aligned
/// - incoming bubbles: light grey, left-aligned
class MaxgramBubble extends StatelessWidget {
  final MaxgramMessage message;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const MaxgramBubble({
    super.key,
    required this.message,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
  });

  static const double _bigRadius = 18;
  static const double _smallRadius = 4;

  BorderRadius _radiusFor(bool outgoing) {
    final tailCorner = _smallRadius;
    final farCorner = _bigRadius;

    if (outgoing) {
      return BorderRadius.only(
        topLeft: Radius.circular(_bigRadius),
        bottomLeft: Radius.circular(_bigRadius),
        topRight: Radius.circular(isFirstInGroup ? _bigRadius : farCorner),
        bottomRight: Radius.circular(isLastInGroup ? tailCorner : farCorner),
      );
    } else {
      return BorderRadius.only(
        topRight: Radius.circular(_bigRadius),
        bottomRight: Radius.circular(_bigRadius),
        topLeft: Radius.circular(isFirstInGroup ? _bigRadius : farCorner),
        bottomLeft: Radius.circular(isLastInGroup ? tailCorner : farCorner),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final outgoing = message.isOutgoing;

    return Align(
      alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          top: isFirstInGroup ? 6 : 2,
          bottom: isLastInGroup ? 6 : 2,
          left: 12,
          right: 12,
        ),
        child: Stack(
          alignment: outgoing ? Alignment.bottomRight : Alignment.bottomLeft,
          children: [
            if (isLastInGroup) _buildTail(outgoing),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: _radiusFor(outgoing),
                  gradient: outgoing
                      ? const LinearGradient(
                          colors: [Color(0xFF4FA9F8), Color(0xFF357FE8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: outgoing ? null : MaxgramColors.secondaryBackground,
                ),
                padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 16,
                        color: outgoing ? Colors.white : MaxgramColors.titleText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: outgoing ? Colors.white70 : MaxgramColors.subtitleText,
                          ),
                        ),
                        if (outgoing) ...[
                          const SizedBox(width: 4),
                          Icon(
                            _statusIcon(message.status),
                            size: 14,
                            color: message.status == MaxgramMessageStatus.read
                                ? Colors.white
                                : Colors.white70,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTail(bool outgoing) {
    return Positioned(
      bottom: 0,
      right: outgoing ? -6 : null,
      left: outgoing ? null : -6,
      child: ClipPath(
        clipper: _TailClipper(outgoing: outgoing),
        child: Container(
          width: 14,
          height: 16,
          decoration: BoxDecoration(
            gradient: outgoing
                ? LinearGradient(
                    colors: (maxgramThemeMode.value == MaxgramThemeMode.dark ? maxgramDark : maxgramLight).outgoingBubbleGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: outgoing ? null : (maxgramThemeMode.value == MaxgramThemeMode.dark ? maxgramDark : maxgramLight).incomingBubble,
          ),
        ),
      ),
    );
  }

  IconData _statusIcon(MaxgramMessageStatus status) {
    switch (status) {
      case MaxgramMessageStatus.sending:
        return Icons.access_time;
      case MaxgramMessageStatus.sent:
        return Icons.done;
      case MaxgramMessageStatus.read:
        return Icons.done_all;
    }
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

/// Custom clipper drawing the small curved "tail" triangle at the
/// bottom corner of the last bubble in a group (Telegram-style).
class _TailClipper extends CustomClipper<Path> {
  final bool outgoing;
  _TailClipper({required this.outgoing});

  @override
  Path getClip(Size size) {
    final path = Path();
    if (outgoing) {
      path.moveTo(0, 0);
      path.quadraticBezierTo(size.width * 0.3, size.height * 0.2, size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
    } else {
      path.moveTo(size.width, 0);
      path.quadraticBezierTo(size.width * 0.7, size.height * 0.2, 0, size.height);
      path.lineTo(size.width, size.height);
      path.close();
    }
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
