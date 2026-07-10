
import 'package:flutter/material.dart';
import 'theme/maxgram_theme.dart';
import 'screens/maxgram_chat_list_screen.dart';
import 'screens/maxgram_auth_screen.dart';
import 'max_protocol/max_client.dart';
import 'max_protocol/max_repository.dart';

void main() => runApp(const MaxgramApp());

class MaxgramApp extends StatefulWidget {
  const MaxgramApp({super.key});

  @override
  State<MaxgramApp> createState() => _MaxgramAppState();
}

class _MaxgramAppState extends State<MaxgramApp> {
  final MaxClient _client = MaxClient();
  late final MaxRepository _repository = MaxRepository(_client);
  bool _authenticated = false;

  @override
  void dispose() {
    _repository.dispose();
    _client.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MaxgramThemeMode>(
      valueListenable: maxgramThemeMode,
      builder: (context, mode, _) {
        final isDark = mode == MaxgramThemeMode.dark;
        return MaterialApp(
          title: 'Maxgram',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.light, scaffoldBackgroundColor: maxgramLight.background),
          darkTheme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: maxgramDark.background),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: _authenticated
              ? MaxgramChatListScreen(repository: _repository)
              : MaxgramAuthScreen(
                  client: _client,
                  onAuthenticated: () => setState(() => _authenticated = true),
                ),
        );
      },
    );
  }
}
