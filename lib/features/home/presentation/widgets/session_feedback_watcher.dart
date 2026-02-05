import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tech_marathon_app/data/models/schedule.dart';
import '../providers/event_stream_providers.dart';
import '../providers/feedback_provider.dart';
import 'session_feedback_dialog.dart';

/// Widget wrapper that monitors active sessions and shows feedback popup
/// when a session ends (if user hasn't already submitted feedback)
class SessionFeedbackWatcher extends ConsumerStatefulWidget {
  final Widget child;

  const SessionFeedbackWatcher({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<SessionFeedbackWatcher> createState() => _SessionFeedbackWatcherState();
}

class _SessionFeedbackWatcherState extends ConsumerState<SessionFeedbackWatcher> {
  Timer? _checkTimer;
  final Set<String> _shownDialogSessionIds = {};
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    // Check every minute for ended sessions
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkForEndedSessions();
    });
    // Also check immediately after a short delay
    Future.delayed(const Duration(seconds: 5), _checkForEndedSessions);
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  void _checkForEndedSessions() {
    if (_isDialogShowing) return;

    final schedulesAsync = ref.read(schedulesStreamProvider);
    final feedbackState = ref.read(feedbackProvider);

    schedulesAsync.whenData((schedules) {
      final now = DateTime.now();
      
      for (final schedule in schedules) {
        // Check if session has ended (within last 30 minutes to avoid old sessions)
        final endTime = schedule.endTime;
        final hasEnded = endTime.isBefore(now);
        final endedRecently = now.difference(endTime).inMinutes <= 30;
        
        // Check if we already showed dialog or user submitted feedback
        final alreadyShown = _shownDialogSessionIds.contains(schedule.id);
        final alreadySubmitted = feedbackState.submittedSessionIds.contains(schedule.id);
        
        if (hasEnded && endedRecently && !alreadyShown && !alreadySubmitted) {
          _showFeedbackDialog(schedule);
          break; // Only show one dialog at a time
        }
      }
    });
  }

  Future<void> _showFeedbackDialog(Schedule schedule) async {
    if (!mounted || _isDialogShowing) return;

    _isDialogShowing = true;
    _shownDialogSessionIds.add(schedule.id);

    await showSessionFeedbackDialog(
      context,
      sessionId: schedule.id,
      sessionTitle: schedule.title,
      eventId: schedule.eventId,
    );

    _isDialogShowing = false;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
