import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/home/domain/event_models.dart';
import '../../../../features/profile/data/profile_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../features/admin/data/admin_repository.dart';
import 'package:go_router/go_router.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final CodingEvent event;
  const PaymentScreen({super.key, required this.event});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isProcessing = false;
  String? _selectedMethod = 'Card';
  bool _isVipSelected = false;
  int _ticketQuantity = 1; // New: ticket quantity

  double get _basePrice => _isVipSelected ? widget.event.vipPrice : widget.event.entryFee;
  double get _vipDiscountAmount => _isVipSelected ? (_basePrice * widget.event.vipDiscountPercentage / 100) : 0;
  double get _earlyBirdAmount => (_basePrice * widget.event.earlyBirdDiscount / 100);
  double get _pricePerTicket => _basePrice - _vipDiscountAmount - _earlyBirdAmount;
  double get _totalAmount => _pricePerTicket * _ticketQuantity; // Updated calculation
  int get _availableSeats => widget.event.availableSeats;

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);
    
    // Simulate payment processing delay
    await Future.delayed(const Duration(seconds: 2));
    
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final txnId = 'TXN-${DateTime.now().millisecondsSinceEpoch}';
      
      // Register event
      await ref.read(profileRepositoryProvider).registerEvent(userId, widget.event.id);
      
      // Create multiple entry passes
      final userName = FirebaseAuth.instance.currentUser?.displayName ?? 'Attendee';
      await ref.read(adminRepositoryProvider).createEntryPass(
        widget.event.id, 
        userId, 
        userName,
        quantity: _ticketQuantity,
        transactionId: txnId,
      );
      
      // Update seat count
      await ref.read(adminRepositoryProvider).updateEventSeats(widget.event.id, _ticketQuantity);
      
      if (mounted) {
        _showSuccessDialog();
      }
    }
  }

  Future<void> _handleCancellation(EntryPass pass) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Cancel Ticket?', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to cancel Ticket #${pass.ticketNumber}? This action cannot be undone.', 
          style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('NO', style: TextStyle(color: AppColors.textDim)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('YES, CANCEL'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          await ref.read(adminRepositoryProvider).cancelTicket(userId, pass.id, widget.event.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ticket cancelled successfully'), backgroundColor: Colors.green),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel ticket: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessDialog() {
    setState(() => _isProcessing = false); // Stop processing immediately
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80)
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              'PAYMENT SUCCESSFUL!',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _ticketQuantity > 1 
                ? '$_ticketQuantity tickets for ${widget.event.name} confirmed.'
                : 'Your ticket for ${widget.event.name} is confirmed.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close payment screen
                  context.go('/my-events'); // Navigate to tickets
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _ticketQuantity > 1 ? 'VIEW TICKETS' : 'VIEW TICKET',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'CHECKOUT',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (userId != null) 
              StreamBuilder<List<EntryPass>>(
                stream: ref.read(adminRepositoryProvider).watchUserEntryPasses(userId, widget.event.id),
                builder: (context, snapshot) {
                  final tickets = snapshot.data ?? [];
                  if (tickets.isEmpty) return const SizedBox.shrink();
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('YOUR EXISTING TICKETS'),
                      const SizedBox(height: 16),
                      ...tickets.map((pass) => _buildTicketCancellationTile(pass)).toList(),
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),

            // Pass Type Selection (Always show Standard at minimum)
            _buildSectionLabel('SELECT PASS TYPE'),
            const SizedBox(height: 16),
            Row(
              children: [
                 _buildPassTypeTab('STANDARD', false),
                 if (widget.event.isVipEnabled) ...[
                   const SizedBox(width: 12),
                   _buildPassTypeTab('VIP PASS', true),
                 ] else 
                   const Spacer(), // Balance the row if only one pass
              ],
            ),
            const SizedBox(height: 32),

            // Quantity Selector (Show if event manages seats)
            if (widget.event.totalSeats > 0) ...[ 
              _buildSectionLabel('NUMBER OF TICKETS'),
              const SizedBox(height: 16),
              _buildQuantitySelector(),
             const SizedBox(height: 32),
            ],

            // Order Summary
            _buildSectionLabel('ORDER SUMMARY'),
            const SizedBox(height: 16),
            _buildOrderCard(),
            const SizedBox(height: 32),
            
            // Payment Methods
            _buildSectionLabel('PAYMENT METHOD'),
            const SizedBox(height: 16),
            _buildMethodTile('Card', Icons.credit_card_rounded, 'Credit / Debit Card'),
            const SizedBox(height: 12),
            _buildMethodTile('UPI', Icons.account_balance_wallet_rounded, 'Google Pay / PhonePe'),
            const SizedBox(height: 12),
            _buildMethodTile('Wallet', Icons.wallet_rounded, 'Zha Wallet'),
            
            const SizedBox(height: 48),
            
            // Pay Button
            if (!widget.event.isEntryScanEnabled)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tickets are currently unavailable because the organizer has disabled scanning for this event.',
                          style: GoogleFonts.inter(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isProcessing || !widget.event.isActive || !widget.event.isEntryScanEnabled || (_availableSeats > 0 && _ticketQuantity > _availableSeats)) 
                  ? null 
                  : _handlePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  disabledBackgroundColor: Colors.grey.shade800,
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(
                        !widget.event.isActive
                          ? 'EVENT CLOSED'
                          : !widget.event.isEntryScanEnabled
                            ? 'BOOKING DISABLED'
                            : (_availableSeats > 0 && _ticketQuantity > _availableSeats)
                              ? 'NOT ENOUGH SEATS'
                              : (_totalAmount == 0 
                                  ? 'CONFIRM BOOKING' 
                                  : 'PAY ${widget.event.currency}${_totalAmount.toStringAsFixed(2)}'),
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCancellationTile(EntryPass pass) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.confirmation_number_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ticket #${pass.ticketNumber}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  pass.status,
                  style: GoogleFonts.inter(fontSize: 11, color: pass.status == 'ACTIVE' ? Colors.green : Colors.orange),
                ),
              ],
            ),
          ),
          if (pass.status == 'ACTIVE')
            TextButton(
              onPressed: _isProcessing ? null : () => _handleCancellation(pass),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildPassTypeTab(String label, bool isVip) {
    final isSelected = _isVipSelected == isVip;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isVipSelected = isVip),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.05), width: 1.5),
            boxShadow: isSelected ? [
              BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
            ] : null,
          ),
          child: Column(
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.event.currency}${isVip ? widget.event.vipPrice.toStringAsFixed(0) : widget.event.entryFee.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.black.withOpacity(0.7) : AppColors.textDim,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        color: AppColors.textDim,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildOrderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: widget.event.imageUrl.isNotEmpty
                    ? Image.network(widget.event.imageUrl, width: 60, height: 60, fit: BoxFit.cover)
                    : Container(width: 60, height: 60, color: Colors.white10),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.event.name,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                    Text(
                      widget.event.location,
                      style: GoogleFonts.inter(color: AppColors.textDim, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Colors.white12),
          ),
          _buildPriceRow('Base Price', '${widget.event.currency}${_basePrice.toStringAsFixed(2)}'),
          if (widget.event.earlyBirdDiscount > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow('Early Bird Discount', '-${widget.event.currency}${_earlyBirdAmount.toStringAsFixed(2)}', isNegative: true),
          ],
          if (_isVipSelected && widget.event.vipDiscountPercentage > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow('VIP Discount', '-${widget.event.currency}${_vipDiscountAmount.toStringAsFixed(2)}', isNegative: true),
          ],
          const SizedBox(height: 8),
          _buildPriceRow('Service Fee', '${widget.event.currency}0.00'),
          if (_ticketQuantity > 1) ...[ 
            const SizedBox(height: 8),
            _buildPriceRow('Price per Ticket', '${widget.event.currency}${_pricePerTicket.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _buildPriceRow('Quantity', 'x$_ticketQuantity'),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Colors.white12),
          ),
          _buildPriceRow('TOTAL AMOUNT', '${widget.event.currency}${_totalAmount.toStringAsFixed(2)}', isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false, bool isNegative = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: isTotal ? Colors.white : AppColors.textDim,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: isTotal ? AppColors.primary : (isNegative ? Colors.greenAccent : Colors.white),
            fontWeight: FontWeight.bold,
            fontSize: isTotal ? 20 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildMethodTile(String id, IconData icon, String title) {
    final isSelected = _selectedMethod == id;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = id),
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.05),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textDim),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : AppColors.textDim,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Quantity',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Row(
                children: [
                  // Minus Button
                  IconButton(
                    onPressed: _ticketQuantity > 1
                        ? () => setState(() => _ticketQuantity--)
                        : null,
                    style: IconButton.styleFrom(
                      backgroundColor: _ticketQuantity > 1 
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: Icon(
                      Icons.remove,
                      color: _ticketQuantity > 1 ? AppColors.primary : Colors.white24,
                    ),
                  ),
                  // Count Display
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '$_ticketQuantity',
                      style: GoogleFonts.outfit(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  // Plus Button
                  IconButton(
                    onPressed: (_availableSeats == 0 || _ticketQuantity < _availableSeats)
                        ? () => setState(() => _ticketQuantity++)
                        : null,
                    style: IconButton.styleFrom(
                      backgroundColor: (_availableSeats == 0 || _ticketQuantity < _availableSeats)
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: Icon(
                      Icons.add,
                      color: (_availableSeats == 0 || _ticketQuantity < _availableSeats)
                        ? AppColors.primary
                        : Colors.white24,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_availableSeats > 0) ...[ 
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _availableSeats <= 5 ? Icons.warning_amber_rounded : Icons.event_seat_rounded,
                  color: _availableSeats <= 5 ? Colors.orange : AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _availableSeats <= 5 
                    ? 'Only $_availableSeats seats remaining!'
                    : '$_availableSeats seats available',
                  style: GoogleFonts.inter(
                    color: _availableSeats <= 5 ? Colors.orange : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ] else if (widget.event.totalSeats > 0) ...[ 
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.block_rounded, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Event is sold out',
                  style: GoogleFonts.inter(color: Colors.red, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
