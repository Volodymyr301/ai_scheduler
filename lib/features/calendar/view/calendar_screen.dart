import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/calendar_cubit.dart';
import '../../authentication/cubit/authentication_cubit.dart';
import '../../authentication/widgets/sign_in_prompt.dart';
import '../../assistant/view/voice_input_screen.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

enum EventFilter { all, today, week }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ScrollController _scrollController = ScrollController();
  EventFilter _selectedFilter = EventFilter.all;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthenticationCubit>().state;
      if (authState.status == AuthenticationStatus.authenticated) {
        context.read<CalendarCubit>().loadUpcomingEvents();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom && !_isLoading && _hasMore) {
      context.read<CalendarCubit>().loadMoreEvents();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  bool get _isLoading {
    final state = context.read<CalendarCubit>().state;
    return state.status == CalendarStatus.loading || state.status == CalendarStatus.loadingMore;
  }

  bool get _hasMore {
    return context.read<CalendarCubit>().state.hasMore;
  }

  List<gcal.Event> _filterEvents(List<gcal.Event> events) {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case EventFilter.all:
        final monthEnd = now.add(const Duration(days: 30));
        return events.where((e) {
          final start = e.start?.dateTime ?? e.start?.date;
          if (start == null) return false;
          return start.isBefore(monthEnd);
        }).toList();
      case EventFilter.today:
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        return events.where((e) {
          final start = e.start?.dateTime ?? e.start?.date;
          if (start == null) return false;
          final eventDate = DateTime(start.year, start.month, start.day);
          return eventDate.isAtSameMomentAs(today) || (eventDate.isAfter(today) && eventDate.isBefore(tomorrow));
        }).toList();
      case EventFilter.week:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 7));
        return events.where((e) {
          final start = e.start?.dateTime ?? e.start?.date;
          if (start == null) return false;
          return start.isAfter(weekStart) && start.isBefore(weekEnd);
        }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              constraints: const BoxConstraints(minHeight: 60),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Події',
                    style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w600, color: const Color(0xFFF8FAFC)),
                  ),
                  BlocBuilder<AuthenticationCubit, AuthenticationState>(
                    builder: (context, authState) {
                      if (authState.status != AuthenticationStatus.authenticated) {
                        return const SizedBox.shrink();
                      }
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => VoiceInputScreen.show(context),
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.add, color: Colors.white, size: 20),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Filters
            BlocBuilder<AuthenticationCubit, AuthenticationState>(
              builder: (context, authState) {
                if (authState.status != AuthenticationStatus.authenticated) {
                  return const SizedBox.shrink();
                }
                return Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'Усі',
                          isSelected: _selectedFilter == EventFilter.all,
                          onTap: () => setState(() => _selectedFilter = EventFilter.all),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Сьогодні',
                          isSelected: _selectedFilter == EventFilter.today,
                          onTap: () => setState(() => _selectedFilter = EventFilter.today),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Тиждень',
                          isSelected: _selectedFilter == EventFilter.week,
                          onTap: () => setState(() => _selectedFilter = EventFilter.week),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Events List
            Expanded(
              child: BlocConsumer<AuthenticationCubit, AuthenticationState>(
                listener: (context, authState) {
                  // Load events when user logs in
                  if (authState.status == AuthenticationStatus.authenticated) {
                    context.read<CalendarCubit>().loadUpcomingEvents();
                  }
                },
                builder: (context, authState) {
                  // Show sign-in prompt if not authenticated
                  if (authState.status != AuthenticationStatus.authenticated) {
                    return const SignInPrompt(
                      title: 'Увійдіть, щоб переглянути події',
                      description: 'Для доступу до Google Calendar необхідно увійти через Google акаунт',
                    );
                  }

                  return BlocBuilder<CalendarCubit, CalendarState>(
                    builder: (context, state) {
                      if (state.status == CalendarStatus.initial ||
                          (state.status == CalendarStatus.loading && state.events.isEmpty)) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
                      }

                      if (state.status == CalendarStatus.failure && state.events.isEmpty) {
                        return Center(
                          child: Text(
                            state.error ?? 'Не вдалося завантажити події',
                            style: const TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        );
                      }

                      final filteredEvents = _filterEvents(state.events);

                      return RefreshIndicator(
                        onRefresh: () => context.read<CalendarCubit>().loadUpcomingEvents(),
                        color: const Color(0xFF3B82F6),
                        backgroundColor: const Color(0xFF1E293B),
                        child: filteredEvents.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 200),
                                  Center(
                                    child: Text('Немає подій', style: TextStyle(color: Color(0xFF94A3B8))),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(top: 8),
                                itemCount:
                                    filteredEvents.length +
                                    (state.hasMore && _selectedFilter == EventFilter.all ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= filteredEvents.length) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                                      ),
                                    );
                                  }

                                  final event = filteredEvents[index];
                                  return _EventListItem(event: event, index: index);
                                },
                              ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: BlocBuilder<AuthenticationCubit, AuthenticationState>(
        builder: (context, authState) {
          if (authState.status != AuthenticationStatus.authenticated) {
            return const SizedBox.shrink();
          }
          return Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 8)),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => VoiceInputScreen.show(context),
                customBorder: const CircleBorder(),
                child: const Center(child: Icon(Icons.mic, size: 24, color: Colors.white)),
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}

class _EventListItem extends StatelessWidget {
  final gcal.Event event;
  final int index;

  const _EventListItem({required this.event, required this.index});

  @override
  Widget build(BuildContext context) {
    final startTimed = event.start?.dateTime;
    final endTimed = event.end?.dateTime;
    final startAllDay = event.start?.date;

    final bool isTimed = startTimed != null || endTimed != null;
    final DateTime start = (startTimed ?? startAllDay ?? DateTime.now()).toLocal();
    final DateTime? end = endTimed?.toLocal();

    final String timeText = isTimed ? _formatTime(start, end) : 'Весь день';
    final int minutesUntil = isTimed ? start.difference(DateTime.now()).inMinutes : 0;

    final now = DateTime.now();
    final tomorrow3am = DateTime(now.year, now.month, now.day + 1, 3, 0);
    final bool shouldShowTimeUntil = isTimed && minutesUntil > 0 && start.isBefore(tomorrow3am);

    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(start.year, start.month, start.day);
    final bool isToday = eventDate.isAtSameMomentAs(today);

    final String dateText = isToday ? 'Сьогодні' : _formatDate(start);

    final List<Color> checkboxColors = [
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF10B981),
    ];
    final checkboxColor = checkboxColors[index % checkboxColors.length];

    return InkWell(
      onTap: () {
        context.push('/event-details', extra: event);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(minHeight: 88),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(20)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox circle
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: checkboxColor, width: 2),
              ),
            ),
            const SizedBox(width: 12),
            // Event details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.summary ?? '(Без назви)',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF8FAFC),
                          ),
                        ),
                      ),
                      if (shouldShowTimeUntil) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            minutesUntil < 60 ? 'За ${minutesUntil} хв' : 'За ${(minutesUntil / 60).round()} год',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        timeText,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isToday ? const Color(0xFF3B82F6).withOpacity(0.1) : const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          dateText,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isToday ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        event.organizer?.displayName ?? 'Календар',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime start, DateTime? end) {
    final startStr = DateFormat('HH:mm').format(start);
    if (end != null) {
      final endStr = DateFormat('HH:mm').format(end);
      return '$startStr - $endStr';
    }
    return startStr;
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM', 'uk').format(date);
  }
}
