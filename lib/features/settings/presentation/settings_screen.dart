import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../auth/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2, fontSize: 12)),
          const SizedBox(height: 16),
          if (user == null) 
            _buildLoginCard(context)
          else 
            _buildProfileCard(context, user),
          
          const SizedBox(height: 32),
          const Text('APPEARANCE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2, fontSize: 12)),
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
          const Text('UNITS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2, fontSize: 12)),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Weight Unit'),
            trailing: Text('kg', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
          ),
          
          const SizedBox(height: 32),
          const Text('ABOUT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2, fontSize: 12)),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Version'),
            trailing: Text('1.0.0', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sync your progress',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Create an account or sign in to backup your workouts and access them on any device.',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('SIGN IN / REGISTER', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.teal,
                child: Text(
                  (user.email ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.email ?? 'Unknown User',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Text('Cloud Sync Active', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.grey),
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Auto-Sync Data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            value: true,
            onChanged: null,
          ),
        ],
      ),
    );
  }
}
