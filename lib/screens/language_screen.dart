import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink_app/services/user_sevice.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _language = 'en';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lang = await UserService.instance.getLanguage();
    if (!mounted) return;
    setState(() => _language = lang);
  }

  Future<void> _setLanguage(String code) async {
    setState(() {
      _language = code;
      _saving = true;
    });
    await UserService.instance.setLanguage(code);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(code == 'en' ? 'English selected' : 'Arabic selected'),
        ),
      );
    }
  }

  Widget _tile(String code, String label) {
    return RadioListTile<String>(
      value: code,
      groupValue: _language,
      onChanged: _saving ? null : (v) => _setLanguage(code),
      title: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language'),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: Column(
        children: [
          _tile('en', 'English'),
          _tile('ar', 'Arabic'),
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(8),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
