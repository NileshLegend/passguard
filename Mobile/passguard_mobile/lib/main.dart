import 'package:flutter/material.dart';

void main() => runApp(const PassGuardApp());

class PassGuardApp extends StatelessWidget {
  const PassGuardApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PassGuard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'sans-serif'),
      home: const CheckerScreen(),
    );
  }
}

class CheckerScreen extends StatefulWidget {
  const CheckerScreen({super.key});
  @override
  State<CheckerScreen> createState() => _CheckerScreenState();
}

class _CheckerScreenState extends State<CheckerScreen> {
  final _controller = TextEditingController();
  int _score = 0;
  String _label = '';
  String _crackTime = '';
  Color _color = Colors.grey;
  bool _obscure = true;

  final List<Color> _colors = [
    Color(0xFFe94560),
    Color(0xFFff9e00),
    Color(0xFFffbe0b),
    Color(0xFF3a86ff),
    Color(0xFF38b000),
  ];

  final List<String> _labels = [
    'Very Weak', 'Weak', 'Fair', 'Strong', 'Very Strong'
  ];

  final List<String> _times = [
    'Instant', 'A few minutes', 'A few hours', 'Months', 'Millions of years'
  ];

  void _checkPassword(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[A-Z]')) && password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[^A-Za-z0-9]'))) score++;
    score = score.clamp(0, 4);

    setState(() {
      _score = score;
      _label = _labels[score];
      _crackTime = _times[score];
      _color = _colors[score];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text('🔥 PassGuard',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                const Text('Check your password strength',
                  style: TextStyle(color: Colors.white54)),
                const SizedBox(height: 40),

                // Input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: TextField(
                    controller: _controller,
                    obscureText: _obscure,
                    style: const TextStyle(color: Colors.white),
                    onChanged: _checkPassword,
                    decoration: InputDecoration(
                      hintText: 'Enter your password...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, color: Colors.white54),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Strength bar
                if (_controller.text.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_score + 1) / 5,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(_color),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Verdict
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(_score >= 3 ? Icons.shield : Icons.warning_amber_rounded, color: _color, size: 32),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_label, style: TextStyle(color: _color, fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Cracks in: $_crackTime', style: const TextStyle(color: Colors.white54)),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tips
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡 Tips', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _tip('Use 12+ characters', _controller.text.length >= 12),
                        _tip('Add uppercase letters', _controller.text.contains(RegExp(r'[A-Z]'))),
                        _tip('Add numbers', _controller.text.contains(RegExp(r'[0-9]'))),
                        _tip('Add special characters (!@#\$)', _controller.text.contains(RegExp(r'[^A-Za-z0-9]'))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tip(String text, bool passed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(passed ? Icons.check_circle : Icons.cancel, color: passed ? Color(0xFF38b000) : Color(0xFFe94560), size: 18),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}