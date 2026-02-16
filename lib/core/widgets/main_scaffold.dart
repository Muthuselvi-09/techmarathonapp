import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/events/presentation/pages/event_timeline_screen.dart';
import '../../features/events/presentation/pages/all_events_screen.dart';
import '../../features/events/presentation/pages/schedule_screen.dart';
import '../../features/home/presentation/pages/schedule_details_screen.dart';
import '../../features/profile/presentation/pages/profile_screen.dart';
import '../../features/home/presentation/widgets/session_feedback_watcher.dart';
import '../../features/home/presentation/pages/professional_calendar_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const HomeScreen(),
    const ScheduleDetailsScreen(), // Professional Overhauled Schedule
    const Scaffold(body: Center(child: Text('QR Pass Placeholder'))), // QR index 2
    const AllEventsScreen(),
    const ProfessionalCalendarScreen(), 
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
       // Center button - open QR pass
       context.push('/qr-pass');
       return;
    }
    
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return SessionFeedbackWatcher(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: _buildBottomNav(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'Home'),
            _buildNavItem(1, Icons.calendar_today_rounded, 'Schedule'),
            _buildCenterQRButton(),
            _buildNavItem(3, Icons.event_note_rounded, 'Event'),
            _buildNavItem(4, Icons.calendar_month_rounded, 'Calendar'),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterQRButton() {
    return GestureDetector(
      onTap: () => _onItemTapped(2),
      child: Container(
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF2D3E42), // Darker teal-grey matching Image 3
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF00CED1) : Colors.white60, // Light teal for selected matching Image 3
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF00CED1) : Colors.white60,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
