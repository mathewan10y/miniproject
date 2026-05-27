import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/settings_provider.dart';
import '../../gamification/user_stats_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final settingsAsync = ref.watch(settingsProvider);
    final isDevMode = ref.watch(devModeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'SYSTEM SETTINGS',
          style: GoogleFonts.orbitron(
            color: Colors.cyan,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.cyan),
      ),
      body: settingsAsync.when(
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Account Info
              _buildSectionHeader('ACCOUNT INFO'),
              _buildCard(
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.cyan, size: 32),
                  title: Text(
                    user?.userMetadata?['username'] ?? 'No Username',
                    style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16),
                  ),
                  subtitle: Text(
                    user?.email ?? 'Unknown Pilot',
                    style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Preferences
              _buildSectionHeader('PREFERENCES'),
              _buildCard(
                child: SwitchListTile(
                  title: Text(
                    'Sound Effects (SFX)',
                    style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16),
                  ),
                  subtitle: Text(
                    'Audio feedback for core systems',
                    style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 12),
                  ),
                  activeColor: Colors.cyan,
                  value: settings.isSfxEnabled,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).toggleSfx();
                  },
                  secondary: Icon(
                    settings.isSfxEnabled ? Icons.volume_up : Icons.volume_off,
                    color: settings.isSfxEnabled ? Colors.cyan : Colors.white54,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildCard(
                child: SwitchListTile(
                  title: Text(
                    'Background Music (BGM)',
                    style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16),
                  ),
                  subtitle: Text(
                    'Continuous ambient atmosphere',
                    style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 12),
                  ),
                  activeColor: Colors.cyan,
                  value: settings.isBgmEnabled,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).toggleBgm();
                  },
                  secondary: Icon(
                    settings.isBgmEnabled ? Icons.music_note : Icons.music_off,
                    color: settings.isBgmEnabled ? Colors.cyan : Colors.white54,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Developer Tools
              _buildSectionHeader('ADVANCED DIAGNOSTICS'),
              _buildCard(
                child: ExpansionTile(
                  leading: const Icon(Icons.developer_mode, color: Colors.amber),
                  title: Text(
                    'Developer Tools',
                    style: GoogleFonts.orbitron(color: Colors.amber, fontSize: 16),
                  ),
                  collapsedIconColor: Colors.amber,
                  iconColor: Colors.amber,
                  children: [
                    SwitchListTile(
                      title: Text(
                        'Dev Mode Override',
                        style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14),
                      ),
                      subtitle: Text(
                        'Enable restricted diagnostic capabilities',
                        style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 12),
                      ),
                      activeColor: Colors.amber,
                      value: isDevMode,
                      onChanged: (val) {
                        ref.read(devModeProvider.notifier).state = val;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Logout Button
              _buildLogoutButton(context),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyan)),
        error: (err, _) => Center(child: Text('Error loading settings', style: TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.orbitron(
          color: Colors.cyan.withOpacity(0.8),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.cyan.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent.withOpacity(0.1),
          foregroundColor: Colors.redAccent,
          side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.power_settings_new),
        label: Text(
          'DISCONNECT COMM LINK',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        onPressed: () async {
          await Supabase.instance.client.auth.signOut();
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
      ),
    );
  }
}
