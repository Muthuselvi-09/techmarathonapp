import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tech_marathon_app/core/theme/app_colors.dart';
import 'package:tech_marathon_app/features/admin/data/admin_repository.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminEntryManagementScreen extends ConsumerStatefulWidget {
  final CodingEvent event;
  const AdminEntryManagementScreen({super.key, required this.event});

  @override
  ConsumerState<AdminEntryManagementScreen> createState() => _AdminEntryManagementScreenState();
}

class _AdminEntryManagementScreenState extends ConsumerState<AdminEntryManagementScreen> {
  bool _isToggling = false;

  @override
  Widget build(BuildContext context) {
    final adminRepo = ref.watch(adminRepositoryProvider);
    final Color gold = const Color(0xFFFFD700);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'ENTRY MANAGEMENT',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _eventCard(gold),
                  const SizedBox(height: 32),
                  _controlSection(adminRepo, gold),
                  const SizedBox(height: 40),
                  Text(
                    'RECENT ENTRY LOGS',
                    style: GoogleFonts.outfit(
                      color: Colors.white30,
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          StreamBuilder<List<EntryPass>>(
            stream: adminRepo.watchEntryPasses(widget.event.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppColors.codingRimPrimary)),
                );
              }

              final passes = snapshot.data ?? [];
              final usedPasses = passes.where((p) => p.status == 'USED').toList();

              if (usedPasses.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off_rounded, color: Colors.white10, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'No entry logs yet',
                          style: GoogleFonts.outfit(color: Colors.white24),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final pass = usedPasses[index];
                    return _logItem(pass, gold);
                  },
                  childCount: usedPasses.length,
                ),
              );
            },
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      floatingActionButton: _scanButton(gold),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _eventCard(Color gold) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage(widget.event.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.name,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.event.location,
                  style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlSection(AdminRepository adminRepo, Color gold) {
    return StreamBuilder<CodingEvent>(
      stream: adminRepo.watchEvents().map((list) => list.firstWhere((e) => e.id == widget.event.id)),
      builder: (context, snapshot) {
        final currentEvent = snapshot.data ?? widget.event;
        final bool isEnabled = currentEvent.isEntryScanEnabled;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isEnabled ? gold.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isEnabled ? gold.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enable Entry Scan',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        isEnabled ? 'Entry is currently ACTIVE' : 'Scanning is DISABLED',
                        style: GoogleFonts.outfit(
                          color: isEnabled ? gold : Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (_isToggling)
                    const CircularProgressIndicator(strokeWidth: 2)
                  else
                    Switch(
                      value: isEnabled,
                      activeThumbColor: gold,
                      activeColor: gold.withValues(alpha: 0.3),
                      onChanged: (val) async {
                        setState(() => _isToggling = true);
                        await adminRepo.toggleEntryScan(widget.event.id, val);
                        if (mounted) setState(() => _isToggling = false);
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _logItem(EntryPass pass, Color gold) {
    final time = pass.entryTime != null ? DateFormat('hh:mm a').format(pass.entryTime!) : '--:--';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pass.userName,
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Verified by Admin',
                  style: GoogleFonts.outfit(color: Colors.white24, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: GoogleFonts.outfit(color: gold, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Text(
                'ENTRY TIME',
                style: TextStyle(color: Colors.white12, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scanButton(Color gold) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gold.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _openScanner(context, gold),
        icon: const Icon(Icons.qr_code_scanner_rounded, size: 24),
        label: Text(
          'START SCANNING',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
      ),
    );
  }

  void _openScanner(BuildContext context, Color gold) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ScannerModal(event: widget.event, gold: gold),
    );
  }
}

class _ScannerModal extends ConsumerStatefulWidget {
  final CodingEvent event;
  final Color gold;
  const _ScannerModal({required this.event, required this.gold});

  @override
  ConsumerState<_ScannerModal> createState() => _ScannerModalState();
}

class _ScannerModalState extends ConsumerState<_ScannerModal> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text(
                'SCAN ENTRY PASS',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              Text(
                'Position the QR code within the frame',
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: widget.gold.withValues(alpha: 0.3), width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: MobileScanner(
                      controller: controller,
                      onDetect: (capture) {
                        if (_isProcessing) return;
                        final List<Barcode> barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                          _processQRCode(barcodes.first.rawValue!);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: ValueListenableBuilder(
                        valueListenable: controller,
                        builder: (context, state, child) {
                          switch (state.torchState) {
                            case TorchState.on:
                              return Icon(Icons.flash_on_rounded, color: widget.gold);
                            case TorchState.off:
                            default:
                              return const Icon(Icons.flash_off_rounded, color: Colors.white54);
                          }
                        },
                      ),
                      onPressed: () => controller.toggleTorch(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white54),
                      onPressed: () => controller.switchCamera(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  void _processQRCode(String rawValue) async {
    setState(() => _isProcessing = true);
    
    // QR Format: eventId:userId:passId
    final parts = rawValue.split(':');
    if (parts.length != 3) {
      _showResultOverlay(false, 'Invalid QR Code Format');
      return;
    }

    final eventId = parts[0];
    // final userId = parts[1];
    final passId = parts[2];

    if (eventId != widget.event.id) {
      _showResultOverlay(false, 'Ticket for a different event');
      return;
    }

    final adminId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_admin';
    final result = await ref.read(adminRepositoryProvider).validateAndProcessPass(
      passId: passId,
      eventId: eventId,
      adminId: adminId,
    );

    if (result == 'SUCCESS') {
      _showResultOverlay(true, 'Access Granted! Welcome');
    } else {
      _showResultOverlay(false, result);
    }
  }

  void _showResultOverlay(bool success, String message) {
    if (!mounted) return;
    
    // Vibrate/Sound would be nice here in a real app

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: success ? Colors.greenAccent.withValues(alpha: 0.3) : Colors.redAccent.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    success ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                    color: success ? Colors.greenAccent : Colors.redAccent,
                    size: 80,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    success ? 'VALID PASS' : 'INVALID PASS',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() => _isProcessing = false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: success ? Colors.greenAccent : Colors.redAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
