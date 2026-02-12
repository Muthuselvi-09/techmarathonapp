import 'package:flutter/material.dart';

class AppIcons {
  // Prevent instantiation
  AppIcons._();

  // Static constant map
  static const Map<int, IconData> _iconMap = {
    0xe22e: Icons.event,
    0xe559: Icons.school,
    0xe13d: Icons.workspace_premium, // Certificate
    0xe112: Icons.calendar_today,
    0xe507: Icons.qr_code,
    0xe314: Icons.history,
    0xe57f: Icons.settings,
    0xe491: Icons.person,
    0xe44f: Icons.notifications,
    0xe22a: Icons.email,
    0xe54c: Icons.security,
    0xe5f9: Icons.star,
    0xe3e0: Icons.local_offer, // My Offers
    0xe098: Icons.bookmark, // Saved Sponsors
    0xe1b0: Icons.error_outline, // Default/Fallback
  };

  static IconData getIcon(int codePoint) {
    return _iconMap[codePoint] ?? Icons.help_outline;
  }
}
