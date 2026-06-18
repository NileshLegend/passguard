import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String API = 'https://passguard-production-2c0c.up.railway.app';

void main() => runApp(const PassGuardApp());

class PassGuardApp extends StatelessWidget {
  const PassGuardApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PassGuard',
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

// Auth Wrapper
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? token;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
      loading = false;
    });
  }

  void setToken(String? t) async {
    final prefs = await SharedPreferences.getInstance();
    if (t == null) {
      prefs.remove('token');
    } else {
      prefs.setString('token', t);
    }
    setState(() => token = t);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (token != null) return DashboardScreen(token: token!, onLogout: () => setToken(null));
    return LoginScreen(onLogin: setToken);
  }
}

// Background gradient
BoxDecoration bgDecoration() => const BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
  ),
);

// Login Screen
class LoginScreen extends StatefulWidget {
  final Function(String) onLogin;
  const LoginScreen({super.key, required this.onLogin});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  String error = '';
  bool loading = false;
  bool isLogin = true;

  Future<void> _submit() async {
    setState(() { loading = true; error = ''; });
    final endpoint = isLogin ? 'login' : 'register';
    try {
      final res = await http.post(
        Uri.parse('$API/auth/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': emailCtrl.text, 'password': passCtrl.text}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        widget.onLogin(data['token']);
      } else {
        setState(() => error = data['error'] ?? 'Something went wrong');
      }
    } catch (e) {
      setState(() => error = 'Connection error');
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: bgDecoration(),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔥 PassGuard', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  const Text('Your Password Manager', style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        Text(isLogin ? 'Login' : 'Register', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 20),
                        if (error.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(color: const Color(0xFFe94560).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                            child: Text(error, style: const TextStyle(color: Color(0xFFe94560))),
                          ),
                        _input(emailCtrl, 'Email'),
                        const SizedBox(height: 12),
                        _input(passCtrl, 'Password', obscure: true),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: loading ? null : _submit,
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFe94560), padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            child: loading ? const CircularProgressIndicator(color: Colors.white) : Text(isLogin ? 'Login' : 'Register', style: const TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => setState(() => isLogin = !isLogin),
                          child: Text(
                            isLogin ? "No account? Register" : "Have an account? Login",
                            style: const TextStyle(color: Color(0xFFe94560)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController ctrl, String hint, {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}

// Dashboard Screen
class DashboardScreen extends StatefulWidget {
  final String token;
  final VoidCallback onLogout;
  const DashboardScreen({super.key, required this.token, required this.onLogout});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;
  List vault = [];

  @override
  void initState() {
    super.initState();
    _loadVault();
  }

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${widget.token}'
  };

  Future<void> _loadVault() async {
    final res = await http.get(Uri.parse('$API/vault'), headers: headers);
    setState(() => vault = jsonDecode(res.body));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: bgDecoration(),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('🔥 PassGuard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    TextButton(
                      onPressed: widget.onLogout,
                      child: const Text('Logout', style: TextStyle(color: Color(0xFFe94560))),
                    ),
                  ],
                ),
              ),
              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _tabBtn('🔍 Checker', 0),
                    const SizedBox(width: 8),
                    _tabBtn('🔐 Vault', 1),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Content
              Expanded(
                child: _tab == 0 ? const CheckerTab() : VaultTab(vault: vault, headers: headers, onRefresh: _loadVault),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabBtn(String label, int index) {
    final active = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFe94560) : Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(color: Colors.white, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}

// Checker Tab
class CheckerTab extends StatefulWidget {
  const CheckerTab({super.key});
  @override
  State<CheckerTab> createState() => _CheckerTabState();
}

class _CheckerTabState extends State<CheckerTab> {
  final ctrl = TextEditingController();
  int score = 0;

  final List<Color> colors = const [Color(0xFFe94560), Color(0xFFff9e00), Color(0xFFffbe0b), Color(0xFF3a86ff), Color(0xFF38b000)];
  final List<String> labels = const ['Very Weak', 'Weak', 'Fair', 'Strong', 'Very Strong'];
  final List<String> times = const ['Instant', 'A few minutes', 'A few hours', 'Months', 'Millions of years'];

  void _check(String password) {
    int s = 0;
    if (password.length >= 8) s++;
    if (password.length >= 12) s++;
    if (password.contains(RegExp(r'[A-Z]')) && password.contains(RegExp(r'[a-z]'))) s++;
    if (password.contains(RegExp(r'[0-9]'))) s++;
    if (password.contains(RegExp(r'[^A-Za-z0-9]'))) s++;
    setState(() => score = s.clamp(0, 4));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Check Password Strength', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  onChanged: _check,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter password...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    suffixIcon: IconButton(icon: const Icon(Icons.clear, color: Colors.white54), onPressed: () { ctrl.clear(); setState(() => score = 0); }),
                  ),
                ),
                if (ctrl.text.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (score + 1) / 5,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(colors[score]),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(score >= 3 ? Icons.shield : Icons.warning_amber_rounded, color: colors[score]),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(labels[score], style: TextStyle(color: colors[score], fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Cracks in: ${times[score]}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Tips
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡 Tips', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _tip('Use 12+ characters', ctrl.text.length >= 12),
                        _tip('Add uppercase letters', ctrl.text.contains(RegExp(r'[A-Z]'))),
                        _tip('Add numbers', ctrl.text.contains(RegExp(r'[0-9]'))),
                        _tip('Add special characters', ctrl.text.contains(RegExp(r'[^A-Za-z0-9]'))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tip(String text, bool passed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(passed ? Icons.check_circle : Icons.cancel, color: passed ? const Color(0xFF38b000) : const Color(0xFFe94560), size: 18),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}

// Vault Tab
class VaultTab extends StatefulWidget {
  final List vault;
  final Map<String, String> headers;
  final VoidCallback onRefresh;
  const VaultTab({super.key, required this.vault, required this.headers, required this.onRefresh});
  @override
  State<VaultTab> createState() => _VaultTabState();
}

class _VaultTabState extends State<VaultTab> {
  final siteCtrl = TextEditingController();
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  Map<int, bool> showPass = {};

  Future<void> _save() async {
    if (siteCtrl.text.isEmpty || userCtrl.text.isEmpty || passCtrl.text.isEmpty) return;
    await http.post(
      Uri.parse('$API/vault'),
      headers: widget.headers,
      body: jsonEncode({'site_name': siteCtrl.text, 'username': userCtrl.text, 'password': passCtrl.text}),
    );
    siteCtrl.clear(); userCtrl.clear(); passCtrl.clear();
    widget.onRefresh();
  }

  Future<void> _delete(int id) async {
    await http.delete(Uri.parse('$API/vault/$id'), headers: widget.headers);
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Add new
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('➕ Save New Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                _input(siteCtrl, 'Site name (e.g. Facebook)'),
                const SizedBox(height: 10),
                _input(userCtrl, 'Username or Email'),
                const SizedBox(height: 10),
                _input(passCtrl, 'Password', obscure: true),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFe94560), padding: const EdgeInsets.all(14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('Save Password', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Saved passwords
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🔐 Saved Passwords', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                if (widget.vault.isEmpty)
                  const Text('No passwords saved yet.', style: TextStyle(color: Colors.white54))
                else
                  ...widget.vault.map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('🌐 ${item['site_name']}', style: const TextStyle(color: Color(0xFFe94560), fontWeight: FontWeight.bold)),
                            GestureDetector(
                              onTap: () => _delete(item['id']),
                              child: const Icon(Icons.delete_outline, color: Color(0xFFe94560), size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('👤 ${item['username']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '🔑 ${showPass[item['id']] == true ? item['password'] : '••••••••'}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'monospace'),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() => showPass[item['id']] = !(showPass[item['id']] ?? false)),
                              child: Text(
                                showPass[item['id']] == true ? 'Hide' : 'Show',
                                style: const TextStyle(color: Color(0xFFe94560), fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(TextEditingController ctrl, String hint, {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}