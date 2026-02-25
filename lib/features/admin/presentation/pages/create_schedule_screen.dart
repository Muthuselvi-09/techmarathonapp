import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/home/domain/event_models.dart';
import '../../../../data/models/schedule.dart' as new_schedule;
import '../../data/admin_repository.dart';
import '../../../home/presentation/providers/event_stream_providers.dart';

class CreateScheduleScreen extends ConsumerStatefulWidget {
  final new_schedule.Schedule? schedule;
  final String? preselectedEventId;

  const CreateScheduleScreen({super.key, this.schedule, this.preselectedEventId});

  @override
  ConsumerState<CreateScheduleScreen> createState() => _CreateScheduleScreenState();
}

class _CreateScheduleScreenState extends ConsumerState<CreateScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _hallController;
  late TextEditingController _capacityController;

  String? _selectedEventId;
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 1));
  DateTime _sessionDate = DateTime.now();
  
  String _sessionType = 'keynote';
  String _status = 'published';
  String _visibility = 'all';
  List<String> _selectedSpeakerIds = [];
  
  bool _isSaving = false;

  final Color _gold = const Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.schedule?.title);
    _descController = TextEditingController(text: widget.schedule?.description);
    _hallController = TextEditingController(text: widget.schedule?.hall ?? widget.schedule?.location);
    _capacityController = TextEditingController(text: widget.schedule?.capacity?.toString());
    
    _selectedEventId = widget.schedule?.eventId ?? widget.preselectedEventId;
    if (widget.schedule != null) {
      _startTime = widget.schedule!.startTime;
      _endTime = widget.schedule!.endTime;
      _sessionDate = widget.schedule!.sessionDate;
      _sessionType = widget.schedule!.sessionType;
      _status = widget.schedule!.status;
      _visibility = widget.schedule!.visibility;
      _selectedSpeakerIds = List.from(widget.schedule!.speakerIds);
    } else {
      _sessionDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _hallController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an event')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Calculate Day dynamically based on Event start date
      int sessionDay = 1;
      final events = await ref.read(adminRepositoryProvider).watchEvents().first;
      final currentEvent = events.firstWhere((e) => e.id == _selectedEventId);
      
      // Calculate difference in days: sessionDate - eventStartDate
      final diff = _sessionDate.difference(DateTime(currentEvent.date.year, currentEvent.date.month, currentEvent.date.day)).inDays;
      sessionDay = (diff >= 0) ? diff + 1 : 1;

      final newSchedule = new_schedule.Schedule(
        id: widget.schedule?.id ?? '',
        eventId: _selectedEventId!,
        day: sessionDay,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        startTime: _startTime,
        endTime: _endTime,
        location: _hallController.text.trim(), // Legacy field preserved for broad compatibility
        mediaUrls: widget.schedule?.mediaUrls ?? [],
        
        hall: _hallController.text.trim(),
        capacity: int.tryParse(_capacityController.text),
        sessionDate: _sessionDate,
        sessionType: _sessionType,
        status: _status,
        visibility: _visibility,
        speakerIds: _selectedSpeakerIds,
      );

      // Conflict Detection
      final conflictError = await ref.read(adminRepositoryProvider).checkScheduleConflict(newSchedule);
      if (conflictError != null && mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 12),
                Text('Conflict Detected', style: GoogleFonts.outfit(color: Colors.white)),
              ],
            ),
            content: Text(conflictError, style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('PROCEED ANYWAY', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        if (proceed != true) {
          setState(() => _isSaving = false);
          return;
        }
      }

      await ref.read(adminRepositoryProvider).saveSchedule(newSchedule, isNew: widget.schedule == null);
      if (mounted) context.pop();

    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving schedule: $e')));
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.schedule == null ? 'New Session' : 'Edit Session',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Selection
              const Text('Assigned Event', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              StreamBuilder<List<CodingEvent>>(
                stream: ref.read(adminRepositoryProvider).watchEvents(),
                builder: (context, snapshot) {
                  return DropdownButtonFormField<String>(
                    value: (snapshot.data ?? []).any((e) => e.id == _selectedEventId) ? _selectedEventId : null,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Select Event'),
                    items: (snapshot.data ?? []).map((e) => DropdownMenuItem(
                      value: e.id,
                      child: Text(
                        e.name, 
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedEventId = val),
                    validator: (v) => v == null ? 'Required' : null,
                  );
                },
              ),
              const SizedBox(height: 24),

              // Info
              _buildSectionHeader('Session Details'),
              _buildTextField(_titleController, 'Session Title', validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              _buildTextField(_hallController, 'Track / Hall Name', validator: (v) => v!.isEmpty ? 'Track/Hall required' : null),
              const SizedBox(height: 16),
              _buildTextField(_descController, 'Description', maxLines: 3),
              const SizedBox(height: 24),

              // Timing & Date
              _buildSectionHeader('Date & Timing'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Session Date', style: TextStyle(color: Colors.white)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                        child: Text('${_sessionDate.day}/${_sessionDate.month}/${_sessionDate.year}', style: TextStyle(color: _gold, fontWeight: FontWeight.bold)),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context, 
                          initialDate: _sessionDate, 
                          firstDate: DateTime(2024), 
                          lastDate: DateTime(2030),
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.dark(primary: _gold, onPrimary: Colors.black, surface: AppColors.surface),
                              textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: _gold)),
                            ),
                            child: child!,
                          ),
                        );
                        if (date != null) {
                          setState(() => _sessionDate = date);
                        }
                      },
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    ListTile(
                      title: const Text('Start Time', style: TextStyle(color: Colors.white)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                        child: Text('${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}', style: TextStyle(color: _gold, fontWeight: FontWeight.bold)),
                      ),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context, 
                          initialTime: TimeOfDay.fromDateTime(_startTime),
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.dark(primary: _gold, onPrimary: Colors.black, surface: AppColors.surface),
                            ),
                            child: child!,
                          ),
                        );
                        if (time != null) {
                          setState(() => _startTime = DateTime(_sessionDate.year, _sessionDate.month, _sessionDate.day, time.hour, time.minute));
                        }
                      },
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    ListTile(
                      title: const Text('End Time', style: TextStyle(color: Colors.white)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                        child: Text('${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}', style: TextStyle(color: _gold, fontWeight: FontWeight.bold)),
                      ),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context, 
                          initialTime: TimeOfDay.fromDateTime(_endTime),
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.dark(primary: _gold, onPrimary: Colors.black, surface: AppColors.surface),
                            ),
                            child: child!,
                          ),
                        );
                        if (time != null) {
                          setState(() => _endTime = DateTime(_sessionDate.year, _sessionDate.month, _sessionDate.day, time.hour, time.minute));
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Configuration
              _buildSectionHeader('Configuration & Control'),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: ['keynote', 'workshop', 'panel', 'break'].contains(_sessionType) ? _sessionType : 'keynote',
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Session Type'),
                      items: const [
                        DropdownMenuItem(value: 'keynote', child: Text('Keynote')),
                        DropdownMenuItem(value: 'workshop', child: Text('Workshop')),
                        DropdownMenuItem(value: 'panel', child: Text('Panel')),
                        DropdownMenuItem(value: 'break', child: Text('Break')),
                      ],
                      onChanged: (val) => setState(() => _sessionType = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(_capacityController, 'Capacity (Opt)', validator: (v) {
                      if (v != null && v.isNotEmpty && int.tryParse(v) == null) return 'Invalid number';
                      return null;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(
                    child: DropdownButtonFormField<String>(
                      value: ['all', 'vip', 'members'].contains(_visibility) ? _visibility : 'all',
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Visibility'),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Visible to All')),
                        DropdownMenuItem(value: 'vip', child: Text('VIP Only')),
                        DropdownMenuItem(value: 'members', child: Text('Members Only')),
                      ],
                      onChanged: (val) => setState(() => _visibility = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                   Expanded(
                    child: DropdownButtonFormField<String>(
                      value: ['published', 'draft', 'cancelled', 'completed'].contains(_status) ? _status : 'published',
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Status'),
                      items: const [
                        DropdownMenuItem(value: 'published', child: Text('Published')),
                        DropdownMenuItem(value: 'draft', child: Text('Draft')),
                        DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      ],
                      onChanged: (val) => setState(() => _status = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Speaker Assignment
              _buildSectionHeader('Speaker Assignment'),
              Consumer(
                builder: (context, ref, child) {
                  final speakersAsync = ref.watch(mergedSpeakersProvider);
                  return speakersAsync.when(
                    data: (speakers) {
                      if (speakers.isEmpty) return const Text('No speakers available', style: TextStyle(color: Colors.white38));
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: speakers.map((speaker) {
                            final isSelected = _selectedSpeakerIds.contains(speaker.id);
                            return CheckboxListTile(
                              value: isSelected,
                              title: Text(speaker.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                              subtitle: Text(speaker.role, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                              activeColor: _gold,
                              checkColor: Colors.black,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedSpeakerIds.add(speaker.id);
                                  } else {
                                    _selectedSpeakerIds.remove(speaker.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Text('Error loading speakers', style: const TextStyle(color: Colors.red)),
                  );
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 100,
        padding: const EdgeInsets.only(bottom: 24),
        child: Center(
          child: SizedBox(
            width: 150,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSaving 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : Text('SAVE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: _gold,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      validator: validator,
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _gold),
      ),
    );
  }
}
