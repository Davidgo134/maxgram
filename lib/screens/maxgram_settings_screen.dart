
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/maxgram_theme.dart';
import '../widgets/maxgram_avatar.dart';

/// Settings screen mirroring Telegram-iOS SettingsUI / ItemListUI:
/// declarative grouped sections with disclosure rows, toggles,
/// and a profile header card at the top (ItemListAvatarAndNameInfoItem).
class MaxgramSettingsScreen extends StatefulWidget {
  final String userName;
  final String userStatus;

  const MaxgramSettingsScreen({
    super.key,
    this.userName = 'Alex Petrov',
    this.userStatus = '+46 70 123 45 67',
  });

  @override
  State<MaxgramSettingsScreen> createState() => _MaxgramSettingsScreenState();
}

class _MaxgramSettingsScreenState extends State<MaxgramSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _readReceipts = true;
  bool _autoDownloadMedia = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: MaxgramColors.secondaryBackground,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Settings'),
        backgroundColor: Colors.white,
      ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 12),
            _profileHeader(),
            const SizedBox(height: 24),
            _section(
              children: [
                _row(icon: Icons.notifications, iconColor: MaxgramColors.swipeArchive, label: 'Notifications', trailing: _switch(_notificationsEnabled, (v) => setState(() => _notificationsEnabled = v))),
                _row(icon: Icons.lock, iconColor: MaxgramColors.accentBlue, label: 'Privacy and Security', showDisclosure: true),
                _row(icon: Icons.data_usage, iconColor: MaxgramColors.unreadBadge, label: 'Data and Storage', showDisclosure: true),
                _row(icon: Icons.color_lens, iconColor: const Color(0xFF9451FF), label: 'Appearance', showDisclosure: true),
                _row(icon: Icons.dark_mode, iconColor: const Color(0xFF3A3A3C), label: 'Dark Mode', trailing: ValueListenableBuilder<MaxgramThemeMode>(valueListenable: maxgramThemeMode, builder: (context, mode, _) => _switch(mode == MaxgramThemeMode.dark, (v) => toggleMaxgramTheme())), isLast: true),
              ],
            ),
            const SizedBox(height: 24),
            _section(
              children: [
                _row(icon: Icons.done_all, iconColor: MaxgramColors.accentBlue, label: 'Read Receipts', trailing: _switch(_readReceipts, (v) => setState(() => _readReceipts = v))),
                _row(icon: Icons.download, iconColor: MaxgramColors.swipeMute, label: 'Auto-Download Media', trailing: _switch(_autoDownloadMedia, (v) => setState(() => _autoDownloadMedia = v)), isLast: true),
              ],
            ),
            const SizedBox(height: 24),
            _section(
              children: [
                _row(icon: Icons.help, iconColor: MaxgramColors.swipeMute, label: 'Ask a Question', showDisclosure: true),
                _row(icon: Icons.info, iconColor: MaxgramColors.swipeMute, label: 'Maxgram FAQ', showDisclosure: true, isLast: true),
              ],
            ),
            const SizedBox(height: 24),
            _section(
              children: [
                _row(icon: Icons.logout, iconColor: MaxgramColors.swipeDelete, label: 'Log Out', isDestructive: true, isLast: true),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _profileHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          MaxgramAvatar(letter: widget.userName[0], colorIndex: 2, size: 64),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userName, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: MaxgramColors.titleText)),
                const SizedBox(height: 2),
                Text(widget.userStatus, style: TextStyle(fontSize: 14, color: MaxgramColors.subtitleText)),
              ],
            ),
          ),
          Icon(Icons.qr_code, color: MaxgramColors.accentBlue),
        ],
      ),
    );
  }

  Widget _section({required List<Widget> children}) {
    return Container(
      color: Colors.white,
      child: Column(children: children),
    );
  }

  Widget _row({
    required IconData icon,
    required Color iconColor,
    required String label,
    Widget? trailing,
    bool showDisclosure = false,
    bool isLast = false,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 29,
                  height: 29,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: iconColor, borderRadius: BorderRadius.circular(7)),
                  alignment: Alignment.center,
                  child: Icon(icon, color: Colors.white, size: 17),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 17,
                      color: isDestructive ? MaxgramColors.swipeDelete : MaxgramColors.titleText,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
                if (showDisclosure)
                  Icon(Icons.chevron_right, color: MaxgramColors.mutedBadge, size: 20),
              ],
            ),
            if (!isLast)
              Padding(
                padding: const EdgeInsets.only(left: 43),
                child: Divider(height: 1, color: MaxgramColors.separator),
              ),
          ],
        ),
      ),
    );
  }

  Widget _switch(bool value, ValueChanged<bool> onChanged) {
    return CupertinoSwitch(value: value, onChanged: onChanged, activeTrackColor: MaxgramColors.unreadBadge);
  }
}
