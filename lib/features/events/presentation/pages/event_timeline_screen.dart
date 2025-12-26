import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/common_widgets.dart';

class EventTimelineScreen extends StatelessWidget {
  const EventTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timeline = [
      {'time': '09:00 AM', 'title': 'Opening Ceremony', 'speaker': 'Lead Organizer'},
      {'time': '10:30 AM', 'title': 'Keynote: Future of Flutter', 'speaker': 'Google Engineer'},
      {'time': '01:00 PM', 'title': 'Lunch & Networking', 'speaker': 'Community'},
      {'time': '02:30 PM', 'title': 'Hackathon Kickoff', 'speaker': 'Tech Leads'},
      {'time': '06:00 PM', 'title': 'Day 1 Wrap-up', 'speaker': 'Event Team'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SCHEDULE'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: timeline.length,
        itemBuilder: (context, index) {
          final item = timeline[index];
          return IntrinsicHeight(
            child: Row(
              children: [
                _buildTimelineIndicator(index == 0, index == timeline.length - 1),
                const SizedBox(width: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['time']!,
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['title']!,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'with ${item['speaker']}',
                            style: const TextStyle(color: AppColors.textDim, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineIndicator(bool isFirst, bool isLast) {
    return Column(
      children: [
        if (!isFirst) Container(width: 2, height: 20, color: Colors.white10),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: CircleAvatar(radius: 4, backgroundColor: Colors.black),
          ),
        ),
        if (!isLast) Expanded(child: Container(width: 2, color: Colors.white10)),
      ],
    );
  }
}
