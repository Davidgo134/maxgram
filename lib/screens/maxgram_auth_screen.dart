
import 'package:flutter/cupertino.dart';
import '../theme/maxgram_theme.dart';
import '../max_protocol/max_client.dart';

/// Two-step phone auth screen wired to MaxClient:
/// 1) enter phone -> sendSmsCode
/// 2) enter SMS code -> signIn -> persist login token
class MaxgramAuthScreen extends StatefulWidget {
  final MaxClient client;
  final VoidCallback onAuthenticated;

  const MaxgramAuthScreen({super.key, required this.client, required this.onAuthenticated});

  @override
  State<MaxgramAuthScreen> createState() => _MaxgramAuthScreenState();
}

class _MaxgramAuthScreenState extends State<MaxgramAuthScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  String? _smsToken;
  bool _loading = false;
  String? _error;

  Future<void> _requestCode() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (!widget.client.isConnected) await widget.client.connect();
      final token = await widget.client.sendSmsCode(_phoneController.text.trim());
      setState(() => _smsToken = token);
    } catch (e) {
      setState(() => _error = 'Не удалось отправить код: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmCode() async {
    if (_smsToken == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final code = int.parse(_codeController.text.trim());
      await widget.client.signIn(_smsToken!, code);
      widget.onAuthenticated();
    } catch (e) {
      setState(() => _error = 'Неверный код или ошибка сети: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: MaxgramColors.background,
      navigationBar: const CupertinoNavigationBar(middle: Text('Вход в Maxgram')),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              if (_smsToken == null) ...[
                Text('Введите номер телефона', style: TextStyle(fontSize: 15, color: MaxgramColors.subtitleText)),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: _phoneController,
                  placeholder: '+46 70 123 45 67',
                  keyboardType: TextInputType.phone,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: MaxgramColors.secondaryBackground, borderRadius: BorderRadius.circular(10)),
                ),
                const SizedBox(height: 16),
                CupertinoButton.filled(
                  onPressed: _loading ? null : _requestCode,
                  child: _loading ? const CupertinoActivityIndicator() : const Text('Получить код'),
                ),
              ] else ...[
                Text('Введите код из SMS', style: TextStyle(fontSize: 15, color: MaxgramColors.subtitleText)),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: _codeController,
                  placeholder: '12345',
                  keyboardType: TextInputType.number,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: MaxgramColors.secondaryBackground, borderRadius: BorderRadius.circular(10)),
                ),
                const SizedBox(height: 16),
                CupertinoButton.filled(
                  onPressed: _loading ? null : _confirmCode,
                  child: _loading ? const CupertinoActivityIndicator() : const Text('Подтвердить'),
                ),
              ],
              if (_error != null) Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: TextStyle(color: MaxgramColors.swipeDelete, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
