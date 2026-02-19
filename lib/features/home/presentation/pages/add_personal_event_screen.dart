import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/event_models.dart';
import '../../../auth/data/user_repository.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class AddPersonalEventScreen extends ConsumerStatefulWidget {
  final DateTime initialDate;
  const AddPersonalEventScreen({super.key, required this.initialDate});

  @override
  ConsumerState<AddPersonalEventScreen> createState() => _AddPersonalEventScreenState();
}

class _AddPersonalEventScreenState extends ConsumerState<AddPersonalEventScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _emailController = TextEditingController();
  
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(hours: 1));
  bool _isAllDay = false;
  String _reminder = '10 mins before';
  String _repeat = 'Don\'t repeat';

  @override
  void initState() {
    super.initState();
    _startDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
      DateTime.now().hour,
      DateTime.now().minute,
    );
    _endDate = _startDate.add(const Duration(hours: 1));
  }

  Future<void> _saveEvent() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    final user = ref.read(profileProvider).user;
    if (user == null) return;

    final event = PersonalEvent(
      id: '',
      userId: user.id,
      title: _titleController.text,
      isAllDay: _isAllDay,
      startDate: _startDate,
      endDate: _endDate,
      location: _locationController.text,
      email: _emailController.text,
      reminder: _reminder,
      repeat: _repeat,
      notes: _notesController.text,
    );

    try {
      await ref.read(userRepositoryProvider).savePersonalEvent(event);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving event: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ),
        leadingWidth: 100,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _saveEvent,
              child: Text('Save', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: GoogleFonts.outfit(color: Colors.white30),
                border: InputBorder.none,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sentiment_satisfied_alt_rounded, color: Colors.white54),
                    const SizedBox(width: 12),
                    Container(width: 20, height: 20, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
                  ],
                ),
              ),
            ),
            const Divider(color: Colors.white12),
            _buildRow(
              icon: Icons.access_time_rounded,
              title: 'All day',
              trailing: Switch(
                value: _isAllDay,
                onChanged: (v) => setState(() => _isAllDay = v),
                activeColor: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDateTimeBlock(_startDate, 'Start'),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white24, size: 20),
                _buildDateTimeBlock(_endDate, 'End'),
              ],
            ),
            const SizedBox(height: 24),
            _buildRow(
              icon: Icons.location_on_outlined,
              title: 'Location',
              trailing: Text('Map', style: GoogleFonts.inter(color: Colors.blue, fontWeight: FontWeight.bold)),
              controller: _locationController,
            ),
            _buildRow(
              icon: Icons.calendar_today_rounded,
              title: 'Email',
              controller: _emailController,
              hint: 'muthuselvi66954@gmail.com',
            ),
            _buildRow(
              icon: Icons.notifications_none_rounded,
              title: 'Notification',
              subtitle: _reminder,
              onTap: () => _showReminderPicker(),
            ),
            _buildRow(
              icon: Icons.repeat_rounded,
              title: 'Repeat',
              subtitle: _repeat,
              onTap: () => _showRepeatPicker(),
            ),
            _buildRow(
              icon: Icons.sticky_note_2_outlined,
              title: 'Notes',
              controller: _notesController,
            ),

            _buildRow(
              icon: Icons.public_rounded,
              title: '(GMT+5:30) India Standard Time',
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  void _showReminderPicker() {
    final options = ['At time of event', '5 mins before', '10 mins before', '15 mins before', '30 mins before', '1 hour before'];
    _showPicker('Notification', options, _reminder, (val) => setState(() => _reminder = val));
  }

  void _showRepeatPicker() {
    final options = ['Don\'t repeat', 'Every day', 'Every week', 'Every month', 'Every year'];
    _showPicker('Repeat', options, _repeat, (val) => setState(() => _repeat = val));
  }

  void _showPicker(String title, List<String> options, String current, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white12),
            ...options.map((opt) => ListTile(
              title: Text(opt, style: GoogleFonts.inter(color: Colors.white70)),
              trailing: opt == current ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () {
                onSelect(opt);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    TextEditingController? controller,
    String? hint,
    VoidCallback? onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: Colors.blue, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (controller != null)
                        TextField(
                          controller: controller,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: hint ?? title,
                            hintStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
                            border: InputBorder.none,
                            isCollapsed: true,
                          ),
                        )
                      else ...[
                        Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 16)),
                        if (subtitle != null)
                          Text(subtitle, style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
        if (!isLast) const Divider(color: Colors.white12, indent: 38),
      ],
    );
  }

  Widget _buildDateTimeBlock(DateTime dt, String label) {
    return Column(
      children: [
        Text(DateFormat('EEE, d MMM').format(dt), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(DateFormat('hh:mm a').format(dt), style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

