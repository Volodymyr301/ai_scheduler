import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../calendar/cubit/calendar_cubit.dart';

class EventDetailsScreen extends StatefulWidget {
  final gcal.Event event;

  const EventDetailsScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _isEditing = false;
  DateTime? _selectedStartDate;
  TimeOfDay? _selectedStartTime;
  DateTime? _selectedEndDate;
  TimeOfDay? _selectedEndTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.summary ?? '');
    _descriptionController = TextEditingController(text: widget.event.description ?? '');
    
    // Initialize date/time from event
    if (widget.event.start?.dateTime != null) {
      _selectedStartDate = widget.event.start!.dateTime!.toLocal();
      _selectedStartTime = TimeOfDay.fromDateTime(_selectedStartDate!);
    }
    if (widget.event.end?.dateTime != null) {
      _selectedEndDate = widget.event.end!.dateTime!.toLocal();
      _selectedEndTime = TimeOfDay.fromDateTime(_selectedEndDate!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Не вказано';
    return DateFormat('d MMMM yyyy, HH:mm', 'uk').format(dateTime);
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'Не вказано';
    return DateFormat('d MMMM yyyy', 'uk').format(dateTime);
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Не вказано';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_selectedStartDate ?? DateTime.now()) : (_selectedEndDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3B82F6),
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
              onSurface: Color(0xFFF8FAFC),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _selectedStartDate = picked;
        } else {
          _selectedEndDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? (_selectedStartTime ?? TimeOfDay.now()) : (_selectedEndTime ?? TimeOfDay.now()),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3B82F6),
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
              onSurface: Color(0xFFF8FAFC),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _selectedStartTime = picked;
        } else {
          _selectedEndTime = picked;
        }
      });
    }
  }

  Future<void> _saveChanges() async {
    // Create a new event with updated values by copying necessary fields
    final updatedEvent = gcal.Event()
      ..id = widget.event.id
      ..summary = _titleController.text
      ..description = _descriptionController.text
      ..location = widget.event.location
      ..attendees = widget.event.attendees
      ..organizer = widget.event.organizer
      ..creator = widget.event.creator
      ..conferenceData = widget.event.conferenceData
      ..reminders = widget.event.reminders
      ..status = widget.event.status
      ..visibility = widget.event.visibility
      ..colorId = widget.event.colorId;
    
    // Update start date/time
    if (_selectedStartDate != null && _selectedStartTime != null) {
      final startDateTime = DateTime(
        _selectedStartDate!.year,
        _selectedStartDate!.month,
        _selectedStartDate!.day,
        _selectedStartTime!.hour,
        _selectedStartTime!.minute,
      );
      updatedEvent.start = gcal.EventDateTime(
        dateTime: startDateTime.toUtc(),
        timeZone: 'UTC',
      );
    } else {
      updatedEvent.start = widget.event.start;
    }
    
    // Update end date/time
    if (_selectedEndDate != null && _selectedEndTime != null) {
      final endDateTime = DateTime(
        _selectedEndDate!.year,
        _selectedEndDate!.month,
        _selectedEndDate!.day,
        _selectedEndTime!.hour,
        _selectedEndTime!.minute,
      );
      updatedEvent.end = gcal.EventDateTime(
        dateTime: endDateTime.toUtc(),
        timeZone: 'UTC',
      );
    } else {
      updatedEvent.end = widget.event.end;
    }

    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
      );
    }

    try {
      // Update event via CalendarCubit
      await context.read<CalendarCubit>().updateEvent(updatedEvent);
      
      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        
        setState(() {
          _isEditing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Зміни збережено', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        
        // Close the details screen and return to refresh
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка збереження: $e', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _cancelEditing() {
    setState(() {
      _titleController.text = widget.event.summary ?? '';
      _descriptionController.text = widget.event.description ?? '';
      if (widget.event.start?.dateTime != null) {
        _selectedStartDate = widget.event.start!.dateTime!.toLocal();
        _selectedStartTime = TimeOfDay.fromDateTime(_selectedStartDate!);
      }
      if (widget.event.end?.dateTime != null) {
        _selectedEndDate = widget.event.end!.dateTime!.toLocal();
        _selectedEndTime = TimeOfDay.fromDateTime(_selectedEndDate!);
      }
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final startDateTime = widget.event.start?.dateTime?.toLocal();
    final endDateTime = widget.event.end?.dateTime?.toLocal();
    final location = widget.event.location;
    final attendees = widget.event.attendees ?? [];
    final calendarId = widget.event.organizer?.displayName ?? widget.event.organizer?.email ?? 'Google Calendar';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFFF8FAFC)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Деталі події',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF8FAFC),
          ),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF3B82F6)),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFFEF4444)),
              onPressed: _cancelEditing,
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check, color: Color(0xFF10B981)),
              onPressed: _saveChanges,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Section
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _isEditing
                              ? TextField(
                                  controller: _titleController,
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFF8FAFC),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Назва події',
                                    hintStyle: GoogleFonts.inter(
                                      color: const Color(0xFF64748B),
                                    ),
                                    border: InputBorder.none,
                                  ),
                                )
                              : Text(
                                  widget.event.summary ?? 'Без назви',
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFF8FAFC),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Date & Time Section
              _SectionCard(
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.calendar_today,
                      label: 'Початок',
                      value: _isEditing
                          ? null
                          : _formatDateTime(startDateTime),
                      editWidget: _isEditing
                          ? Row(
                              children: [
                                Expanded(
                                  child: _EditButton(
                                    text: _formatDate(_selectedStartDate),
                                    onTap: () => _selectDate(context, true),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _EditButton(
                                    text: _formatTime(_selectedStartTime),
                                    onTap: () => _selectTime(context, true),
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Icons.access_time,
                      label: 'Кінець',
                      value: _isEditing
                          ? null
                          : _formatDateTime(endDateTime),
                      editWidget: _isEditing
                          ? Row(
                              children: [
                                Expanded(
                                  child: _EditButton(
                                    text: _formatDate(_selectedEndDate),
                                    onTap: () => _selectDate(context, false),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _EditButton(
                                    text: _formatTime(_selectedEndTime),
                                    onTap: () => _selectTime(context, false),
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Calendar Section
              _SectionCard(
                child: _DetailRow(
                  icon: Icons.event_note,
                  label: 'Календар',
                  value: calendarId,
                  valueColor: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(height: 16),

              // Location Section
              if (location != null && location.isNotEmpty)
                _SectionCard(
                  child: _DetailRow(
                    icon: Icons.location_on,
                    label: 'Місце',
                    value: location,
                  ),
                ),
              if (location != null && location.isNotEmpty)
                const SizedBox(height: 16),

              // Description Section
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.description,
                          size: 20,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Опис',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _isEditing
                        ? TextField(
                            controller: _descriptionController,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFFF8FAFC),
                            ),
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: 'Додайте опис...',
                              hintStyle: GoogleFonts.inter(
                                color: const Color(0xFF64748B),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF334155),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF334155),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                            ),
                          )
                        : Text(
                            widget.event.description ?? 'Опис відсутній',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: widget.event.description != null
                                  ? const Color(0xFFF8FAFC)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Attendees Section
              if (attendees.isNotEmpty)
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.people,
                            size: 20,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Учасники (${attendees.length})',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...attendees.map((attendee) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF334155),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      (attendee.displayName ?? attendee.email ?? '?')[0].toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFF8FAFC),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (attendee.displayName != null)
                                        Text(
                                          attendee.displayName!,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFFF8FAFC),
                                          ),
                                        ),
                                      if (attendee.email != null)
                                        Text(
                                          attendee.email!,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (attendee.responseStatus != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getAttendeeStatusColor(attendee.responseStatus!).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _getAttendeeStatusText(attendee.responseStatus!),
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: _getAttendeeStatusColor(attendee.responseStatus!),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),

              // Additional Info Section
              if (widget.event.conferenceData?.entryPoints != null &&
                  widget.event.conferenceData!.entryPoints!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _SectionCard(
                    child: _DetailRow(
                      icon: Icons.videocam,
                      label: 'Відеоконференція',
                      value: widget.event.conferenceData!.entryPoints!.first.label ?? 'Google Meet',
                      valueColor: const Color(0xFF10B981),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAttendeeStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return const Color(0xFF10B981);
      case 'declined':
        return const Color(0xFFEF4444);
      case 'tentative':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _getAttendeeStatusText(String status) {
    switch (status) {
      case 'accepted':
        return 'Прийнято';
      case 'declined':
        return 'Відхилено';
      case 'tentative':
        return 'Можливо';
      default:
        return 'Немає відповіді';
    }
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color? valueColor;
  final Widget? editWidget;

  const _DetailRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueColor,
    this.editWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF64748B),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 4),
              if (editWidget != null)
                editWidget!
              else if (value != null)
                Text(
                  value!,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? const Color(0xFFF8FAFC),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _EditButton({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF334155),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFF8FAFC),
                ),
              ),
            ),
            const Icon(
              Icons.edit,
              size: 16,
              color: Color(0xFF3B82F6),
            ),
          ],
        ),
      ),
    );
  }
}

