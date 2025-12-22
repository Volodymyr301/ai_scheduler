import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../authentication/cubit/authentication_cubit.dart';
import '../../authentication/widgets/sign_in_prompt.dart';
import '../../calendar/cubit/calendar_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 60),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                'Налаштування',
                style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w600, color: const Color(0xFFF8FAFC)),
              ),
            ),
            Expanded(
              child: BlocBuilder<AuthenticationCubit, AuthenticationState>(
                builder: (context, state) {
                  // Show sign-in prompt if not authenticated
                  if (state.status != AuthenticationStatus.authenticated) {
                    return const SignInPrompt(
                      title: 'Увійдіть до налаштувань',
                      description: 'Для доступу до налаштувань необхідно увійти через Google акаунт',
                    );
                  }

                  final user = state.user!;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        // Profile Avatar
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: const EdgeInsets.all(3),
                          child: Container(
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0F172A)),
                            padding: const EdgeInsets.all(3),
                            child: ClipOval(
                              child: user.photoUrl != null
                                  ? Image.network(user.photoUrl!, fit: BoxFit.cover)
                                  : const Icon(Icons.person, size: 50, color: Color(0xFF94A3B8)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // User Name
                        Text(
                          user.displayName ?? 'Користувач',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF8FAFC),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // User Email
                        Text(
                          user.email,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Calendars Section
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Календарі',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Google Calendar Card
                        _CalendarCard(
                          icon: Icons.calendar_today,
                          iconColor: const Color(0xFF3B82F6),
                          title: 'Google Calendar',
                          status: 'Підключено',
                          statusColor: const Color(0xFF10B981),
                          isEnabled: true,
                          onChanged: null, // Disabled - can't turn off
                        ),
                        const SizedBox(height: 12),
                        // Outlook Calendar Card
                        _CalendarCard(
                          icon: Icons.calendar_month,
                          iconColor: const Color(0xFF0078D4),
                          title: 'Outlook Calendar',
                          status: 'Не підключено',
                          statusColor: const Color(0xFF64748B),
                          isEnabled: false,
                          onChanged: null, // Disabled - can't turn on
                        ),
                        const SizedBox(height: 12),
                        // Apple Calendar Card
                        _CalendarCard(
                          icon: Icons.apple,
                          iconColor: const Color(0xFF94A3B8),
                          title: 'Apple Calendar',
                          status: 'Не підключено',
                          statusColor: const Color(0xFF64748B),
                          isEnabled: false,
                          onChanged: null, // Disabled - can't turn on
                        ),
                        const SizedBox(height: 32),
                        // Sign Out Button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Акаунт',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SettingsTile(
                          icon: Icons.logout,
                          title: 'Вийти',
                          onTap: () {
                            context.read<CalendarCubit>().clear();
                            context.read<AuthenticationCubit>().signOut();
                          },
                          isDestructive: true,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String status;
  final Color statusColor;
  final bool isEnabled;
  final ValueChanged<bool>? onChanged;

  const _CalendarCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.status,
    required this.statusColor,
    required this.isEnabled,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          // Calendar Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          // Calendar Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFFF8FAFC)),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: statusColor),
                ),
              ],
            ),
          ),
          // Toggle Switch
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: isEnabled,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFF10B981),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsTile({required this.icon, required this.title, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF94A3B8), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFFF8FAFC),
                ),
              ),
            ),
            if (!isDestructive) const Icon(Icons.chevron_right, color: Color(0xFF64748B), size: 20),
          ],
        ),
      ),
    );
  }
}
