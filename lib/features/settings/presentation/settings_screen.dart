import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('APPEARANCE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 16),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
            ],
            selected: {themeMode},
            onSelectionChanged: (val) {
              ref.read(themeModeProvider.notifier).setThemeMode(val.first);
            },
          ),
          const SizedBox(height: 32),
          if (user == null) ...[
            const Text(
              'Sign in to sync your data across devices.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleAuth,
                child: Text(_isLogin ? 'LOG IN' : 'SIGN UP'),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(_isLogin ? 'Need an account? Sign up' : 'Already have an account? Log in'),
            ),
          ] else ...[
            ListTile(
              title: const Text('Logged in as'),
              subtitle: Text(user.email ?? 'Unknown'),
              trailing: IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  setState(() {});
                },
              ),
            ),
            const Divider(),
            const SwitchListTile(
              title: Text('Backup to Cloud'),
              subtitle: Text('Sync your workouts automatically'),
              value: true,
              onChanged: null, // Placeholder
            ),
          ],
          const SizedBox(height: 32),
          const Text('UNITS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const ListTile(
            title: Text('Weight Unit'),
            trailing: Text('kg', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAuth() async {
    try {
      if (_isLogin) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await Supabase.instance.client.auth.signUp(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}
