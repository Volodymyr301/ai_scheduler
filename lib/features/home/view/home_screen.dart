import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../authentication/cubit/authentication_cubit.dart';
import '../../authentication/widgets/sign_in_prompt.dart';
import '../../calendar/cubit/calendar_cubit.dart';
import '../../voice/view/voice_input_screen.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthenticationCubit>().state;
      if (authState.status == AuthenticationStatus.authenticated) {
        context.read<CalendarCubit>().loadUpcomingEvents();
      }
    });
  }

  List<gcal.Event> _getTodayEvents(List<gcal.Event> events) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    return events.where((e) {
      final start = e.start?.dateTime ?? e.start?.date;
      if (start == null) return false;
      final eventDate = DateTime(start.year, start.month, start.day);
      return eventDate.isAtSameMomentAs(today) || 
             (eventDate.isAfter(today) && eventDate.isBefore(tomorrow));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: BlocBuilder<AuthenticationCubit, AuthenticationState>(
                      builder: (context, state) {
                        String greeting = 'Привіт!';
                        if (state.status == AuthenticationStatus.authenticated && state.user != null) {
                          final userName = state.user!.displayName?.split(' ').first ?? 
                                          state.user!.email.split('@').first;
                          greeting = 'Привіт, $userName';
                        }
                        return Text(
                          greeting,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF8FAFC),
                          ),
                        );
                      },
                    ),
                  ),
                  BlocBuilder<AuthenticationCubit, AuthenticationState>(
                    builder: (context, state) {
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF334155),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: state.status == AuthenticationStatus.authenticated && 
                                 state.user?.photoUrl != null
                              ? Image.network(
                                  state.user!.photoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.person,
                                      size: 20,
                                      color: Color(0xFF94A3B8),
                                    );
                                  },
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 20,
                                  color: Color(0xFF94A3B8),
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            // Center content
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Що плануємо сьогодні?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Microphone button
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                        center: Alignment.center,
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.4),
                          blurRadius: 40,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final authState = context.read<AuthenticationCubit>().state;
                          if (authState.status != AuthenticationStatus.authenticated) {
                            showSignInDialog(context);
                          } else {
                            VoiceInputScreen.show(context);
                          }
                        },
                        customBorder: const CircleBorder(),
                        child: Center(
                          child: Icon(
                            Icons.mic,
                            size: 48,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Today's events section
            BlocListener<AuthenticationCubit, AuthenticationState>(
              listener: (context, authState) {
                // Load events when user logs in
                if (authState.status == AuthenticationStatus.authenticated) {
                  context.read<CalendarCubit>().loadUpcomingEvents();
                }
              },
              child: BlocBuilder<CalendarCubit, CalendarState>(
                builder: (context, state) {
                  final todayEvents = _getTodayEvents(state.events);
                  
                  if (todayEvents.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 24, bottom: 16),
                        child: Text(
                          'Сьогодні',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF8FAFC),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                          itemCount: todayEvents.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(right: index < todayEvents.length - 1 ? 12 : 0),
                              child: _TodayEventCard(
                                event: todayEvents[index],
                                index: index,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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

class _TodayEventCard extends StatelessWidget {
  final gcal.Event event;
  final int index;

  const _TodayEventCard({required this.event, required this.index});

  @override
  Widget build(BuildContext context) {
    final startTimed = event.start?.dateTime;
    final endTimed = event.end?.dateTime;
    
    final bool isTimed = startTimed != null || endTimed != null;
    final DateTime start = (startTimed ?? event.start?.date ?? DateTime.now()).toLocal();
    final DateTime? end = endTimed?.toLocal();

    final String timeText = isTimed && end != null
        ? '${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}'
        : 'Весь день';
    
    final int minutesUntil = isTimed ? start.difference(DateTime.now()).inMinutes : 0;

    // Перевірка чи подія не пізніше 3:00 наступного дня
    final now = DateTime.now();
    final tomorrow3am = DateTime(now.year, now.month, now.day + 1, 3, 0);
    final bool shouldShowTimeUntil = isTimed && minutesUntil > 0 && start.isBefore(tomorrow3am);

    // Градієнти для карток
    final List<List<Color>> gradients = [
      [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
      [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
      [const Color(0xFF10B981), const Color(0xFF059669)],
      [const Color(0xFFEC4899), const Color(0xFFDB2777)],
      [const Color(0xFFF59E0B), const Color(0xFFD97706)],
    ];
    final gradient = gradients[index % gradients.length];

    return Container(
      width: 280,
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.calendar_today,
                size: 24,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  event.summary ?? '(Без назви)',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (shouldShowTimeUntil)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    minutesUntil < 60
                        ? 'За ${minutesUntil} хв'
                        : 'За ${(minutesUntil / 60).round()} год',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            timeText,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

