
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Maxgram theme system — light & dark palettes visually inspired by
/// Telegram-iOS PresentationTheme (submodules/TelegramPresentationData),
/// reinterpreted for Flutter via ValueNotifier-based theme switching.
enum MaxgramThemeMode { light, dark }

/// Global theme mode notifier — swap at runtime without app restart.
final ValueNotifier<MaxgramThemeMode> maxgramThemeMode =
    ValueNotifier(MaxgramThemeMode.light);

class MaxgramPalette {
  final Color background;
  final Color secondaryBackground;
  final Color separator;
  final Color accentBlue;
  final Color unreadBadge;
  final Color mutedBadge;
  final Color titleText;
  final Color subtitleText;
  final Color swipeArchive;
  final Color swipeDelete;
  final Color swipeMute;
  final Color incomingBubble;
  final List<Color> outgoingBubbleGradient;
  final Color navBarBackground;
  final Color inputBackground;
  final Color overlayScrim;
  final Color menuBackground;

  const MaxgramPalette({
    required this.background,
    required this.secondaryBackground,
    required this.separator,
    required this.accentBlue,
    required this.unreadBadge,
    required this.mutedBadge,
    required this.titleText,
    required this.subtitleText,
    required this.swipeArchive,
    required this.swipeDelete,
    required this.swipeMute,
    required this.incomingBubble,
    required this.outgoingBubbleGradient,
    required this.navBarBackground,
    required this.inputBackground,
    required this.overlayScrim,
    required this.menuBackground,
  });
}

/// Light palette — matches default Telegram-iOS "Day Classic" theme.
const MaxgramPalette maxgramLight = MaxgramPalette(
  background: Color(0xFFFFFFFF),
  secondaryBackground: Color(0xFFF7F7F7),
  separator: Color(0xFFC6C6C8),
  accentBlue: Color(0xFF007AFF),
  unreadBadge: Color(0xFF4FAE4E),
  mutedBadge: Color(0xFFB6B6BB),
  titleText: Color(0xFF000000),
  subtitleText: Color(0xFF8E8E93),
  swipeArchive: Color(0xFFFF9500),
  swipeDelete: Color(0xFFFF3B30),
  swipeMute: Color(0xFF8E8E93),
  incomingBubble: Color(0xFFF1F1F1),
  outgoingBubbleGradient: [Color(0xFF4FA9F8), Color(0xFF357FE8)],
  navBarBackground: Color(0xFFFFFFFF),
  inputBackground: Color(0xFFF7F7F7),
  overlayScrim: Color(0x40000000),
  menuBackground: Color(0xFFFFFFFF),
);

/// Dark palette — matches Telegram-iOS "Night" theme
/// (deep navy backgrounds, desaturated accents, dimmed separators).
const MaxgramPalette maxgramDark = MaxgramPalette(
  background: Color(0xFF18222D),
  secondaryBackground: Color(0xFF212B36),
  separator: Color(0xFF303B45),
  accentBlue: Color(0xFF3E88F7),
  unreadBadge: Color(0xFF4FAE4E),
  mutedBadge: Color(0xFF6D7883),
  titleText: Color(0xFFFFFFFF),
  subtitleText: Color(0xFF8E99A3),
  swipeArchive: Color(0xFFFF9F0A),
  swipeDelete: Color(0xFFFF453A),
  swipeMute: Color(0xFF6D7883),
  incomingBubble: Color(0xFF283542),
  outgoingBubbleGradient: [Color(0xFF2B5B9E), Color(0xFF1F4275)],
  navBarBackground: Color(0xFF212B36),
  inputBackground: Color(0xFF212B36),
  overlayScrim: Color(0x66000000),
  menuBackground: Color(0xFF283542),
);

/// Static accessor kept for backward compatibility with earlier widgets
/// (MaxgramColors.xxx) — now proxies to the active palette.
class MaxgramColors {
  static MaxgramPalette get _p =>
      maxgramThemeMode.value == MaxgramThemeMode.dark ? maxgramDark : maxgramLight;

  static Color get background => _p.background;
  static Color get secondaryBackground => _p.secondaryBackground;
  static Color get separator => _p.separator;
  static Color get accentBlue => _p.accentBlue;
  static Color get unreadBadge => _p.unreadBadge;
  static Color get mutedBadge => _p.mutedBadge;
  static Color get titleText => _p.titleText;
  static Color get subtitleText => _p.subtitleText;
  static Color get swipeArchive => _p.swipeArchive;
  static Color get swipeDelete => _p.swipeDelete;
  static Color get swipeMute => _p.swipeMute;

  static const List<Color> avatarGradients0 = [Color(0xFFFF885E), Color(0xFFFF516A)];
  static const List<Color> avatarGradients1 = [Color(0xFFFFCD6A), Color(0xFFFFA85C)];
  static const List<Color> avatarGradients2 = [Color(0xFF82B1FF), Color(0xFF665FFF)];
  static const List<Color> avatarGradients3 = [Color(0xFF54CB68), Color(0xFF2AB6AB)];
  static const List<Color> avatarGradients4 = [Color(0xFF6F7DFF), Color(0xFF9451FF)];
}

class MaxgramCurves {
  static const Curve navBarCollapse = Cubic(0.25, 0.1, 0.25, 1.0);
  static const Curve swipeElastic = Curves.easeOutBack;
  static const Curve listItemAppear = Curves.easeOutCubic;
}

/// Widget that rebuilds its subtree whenever theme mode changes.
/// Wrap the app root (or individual screens) with this to react live.
class MaxgramThemeScope extends StatelessWidget {
  final Widget Function(BuildContext context, MaxgramPalette palette) builder;

  const MaxgramThemeScope({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MaxgramThemeMode>(
      valueListenable: maxgramThemeMode,
      builder: (context, mode, _) {
        final palette = mode == MaxgramThemeMode.dark ? maxgramDark : maxgramLight;
        return builder(context, palette);
      },
    );
  }
}

void toggleMaxgramTheme() {
  maxgramThemeMode.value = maxgramThemeMode.value == MaxgramThemeMode.dark
      ? MaxgramThemeMode.light
      : MaxgramThemeMode.dark;
}
