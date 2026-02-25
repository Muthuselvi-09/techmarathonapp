import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/home/domain/event_models.dart';
// import 'package:flutter/foundation.dart' hide Category; // Already handled in event_models if needed, but here it is foundation

import '../../data/admin_repository.dart';
import '../providers/optimistic_state_provider.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  final CodingEvent? event;

  const CreateEventScreen({super.key, this.event});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _descController;
  late TextEditingController _feeController;
  late TextEditingController _totalSeatsController;
  late TextEditingController _currencyController;
  late TextEditingController _entryTimingController;
  late TextEditingController _vipPriceController;
  late TextEditingController _vipDiscountController;
  late TextEditingController _earlyBirdDiscountController;
  late List<String> _rules;
  
  XFile? _selectedImage;
  String? _currentImageUrl;
  String? _selectedCategoryId;
  bool _isFree = true;
  bool _isVipEnabled = false;
  bool _isSaving = false;

  final Color _gold = const Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.name);
    _locationController = TextEditingController(text: widget.event?.location);
    _descController = TextEditingController(text: widget.event?.description);
    _feeController = TextEditingController(text: widget.event?.entryFee.toString());
    _totalSeatsController = TextEditingController(text: widget.event?.totalSeats.toString() ?? '0');
    _currencyController = TextEditingController(text: widget.event?.currency ?? '₹');
    _entryTimingController = TextEditingController(text: widget.event?.entryTiming);
    _vipPriceController = TextEditingController(text: widget.event?.vipPrice.toString() ?? '0.0');
    _vipDiscountController = TextEditingController(text: widget.event?.vipDiscountPercentage.toString() ?? '0.0');
    _earlyBirdDiscountController = TextEditingController(text: widget.event?.earlyBirdDiscount.toString() ?? '0.0');
    _rules = List<String>.from(widget.event?.rules ?? []);
    _currentImageUrl = widget.event?.imageUrl;
    _selectedCategoryId = widget.event?.categoryId;
    _isFree = widget.event?.isFree ?? true;
    _isVipEnabled = widget.event?.isVipEnabled ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descController.dispose();
    _feeController.dispose();
    _totalSeatsController.dispose();
    _currencyController.dispose();
    _entryTimingController.dispose();
    _vipPriceController.dispose();
    _vipDiscountController.dispose();
    _earlyBirdDiscountController.dispose();
    super.dispose();
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_titleController.text.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final price = double.tryParse(_feeController.text) ?? 0.0;
      
      final repo = ref.read(adminRepositoryProvider);
      final categories = await repo.watchCategories().first;
      final catName = categories.firstWhere(
        (c) => c.id == _selectedCategoryId, 
        orElse: () => Category(id: '', name: 'All')
      ).name;

      final optimisticEvent = CodingEvent(
        id: widget.event?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
        name: _titleController.text,
        location: _locationController.text,
        category: catName,
        categoryId: _selectedCategoryId,
        isFree: _isFree,
        entryFee: _isFree ? 0.0 : price,
        currency: _currencyController.text,
        description: _descController.text,
        date: widget.event?.date ?? DateTime.now(),
        speakerIds: widget.event?.speakerIds ?? [],
        imageUrl: _currentImageUrl ?? 'https://images.unsplash.com/photo-1540575467063-178a50c2df87',
        entryTiming: _entryTimingController.text,
        rules: _rules.where((r) => r.trim().isNotEmpty).toList(),
        totalSeats: int.tryParse(_totalSeatsController.text) ?? 0,
        bookedSeats: widget.event?.bookedSeats ?? 0,
        isVipEnabled: _isVipEnabled,
        vipPrice: double.tryParse(_vipPriceController.text) ?? 0.0,
        vipDiscountPercentage: double.tryParse(_vipDiscountController.text) ?? 0.0,
        earlyBirdDiscount: double.tryParse(_earlyBirdDiscountController.text) ?? 0.0,
      );

      // Optimistic update
      if (widget.event == null) {
        ref.read(optimisticEventsProvider.notifier).addEvent(optimisticEvent);
      } else {
        ref.read(optimisticEventsProvider.notifier).updateEvent(optimisticEvent);
      }

      if (mounted) context.pop();

      await ref.read(adminRepositoryProvider).saveEvent(
        optimisticEvent,
        isNew: widget.event == null,
        imageFile: _selectedImage,
      );

      // Remove optimistic event after delay (assuming real data arrives via stream)
      Future.delayed(const Duration(seconds: 3), () {
        ref.read(optimisticEventsProvider.notifier).removeEvent(optimisticEvent.id);
      });

    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving event: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.event == null ? 'New Event' : 'Edit Event',
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
              // Cover Image
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                  if (image != null) {
                    setState(() => _selectedImage = image);
                  }
                },
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(16),
                    image: _selectedImage != null 
                      ? DecorationImage(
                          image: kIsWeb 
                              ? NetworkImage(_selectedImage!.path) 
                              : FileImage(File(_selectedImage!.path)) as ImageProvider,
                          fit: BoxFit.cover
                        )
                      : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                        ? DecorationImage(image: NetworkImage(_currentImageUrl!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _selectedImage == null && (_currentImageUrl == null || _currentImageUrl!.isEmpty)
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_rounded, color: Colors.white54, size: 48),
                          const SizedBox(height: 8),
                          Text('Add Cover Image', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14)),
                        ],
                      )
                    : null,
                ),
              ),
              const SizedBox(height: 24),

              // Basic Info
              _buildSectionHeader('Event Details'),
              _buildTextField(_titleController, 'Event Title', validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              _buildTextField(_locationController, 'Location'),
              const SizedBox(height: 16),
              _buildTextField(_totalSeatsController, 'Total Seats', keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              
              const Text('Category', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              StreamBuilder<List<Category>>(
                stream: ref.watch(adminRepositoryProvider).watchCategories(),
                builder: (context, snapshot) {
                  return DropdownButtonFormField<String>(
                    value: (snapshot.data ?? []).any((c) => c.id == _selectedCategoryId) ? _selectedCategoryId : null,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Select Category'),
                    items: (snapshot.data ?? []).where((c) => c.isEnabled).map((cat) => DropdownMenuItem<String>(
                      value: cat.id,
                      child: Text(cat.name),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                  );
                },
              ),
              
              const SizedBox(height: 24),

              // Pricing
              _buildSectionHeader('Pricing'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Free Event', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16)),
                    Switch(
                      value: _isFree,
                      onChanged: (val) => setState(() => _isFree = val),
                      activeColor: _gold,
                      activeTrackColor: _gold.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
              if (!_isFree) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Currency', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: ['₹', '\$', '€', '£', '¥', 'AED', 'SAR'].contains(_currencyController.text) ? _currencyController.text : '₹',
                            dropdownColor: AppColors.surface,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(''),
                            items: const [
                              DropdownMenuItem(value: '₹', child: Text('₹ (INR)')),
                              DropdownMenuItem(value: '\$', child: Text('\$ (USD)')),
                              DropdownMenuItem(value: '€', child: Text('€ (EUR)')),
                              DropdownMenuItem(value: '£', child: Text('£ (GBP)')),
                              DropdownMenuItem(value: '¥', child: Text('¥ (JPY)')),
                              DropdownMenuItem(value: 'AED', child: Text('AED')),
                              DropdownMenuItem(value: 'SAR', child: Text('SAR')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _currencyController.text = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20), // Align with dropdown
                        child: _buildTextField(_feeController, 'Entry Fee', keyboardType: TextInputType.number),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // VIP & Discounts
              _buildSectionHeader('VIP & Discounts'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Enable VIP Pass', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16)),
                    Switch(
                      value: _isVipEnabled,
                      onChanged: (val) => setState(() => _isVipEnabled = val),
                      activeColor: _gold,
                      activeTrackColor: _gold.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
              if (_isVipEnabled) ...[
                const SizedBox(height: 16),
                _buildTextField(_vipPriceController, 'VIP Base Price', keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_vipDiscountController, 'VIP Discount %', keyboardType: TextInputType.number)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(_earlyBirdDiscountController, 'Early Bird %', keyboardType: TextInputType.number)),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Description & Rules
              _buildSectionHeader('Description & Rules'),
              _buildTextField(_descController, 'Description', maxLines: 5),
              const SizedBox(height: 16),
              _buildTextField(_entryTimingController, 'Entry Timing (e.g. 8:00 AM)'),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Rules & Instructions', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  TextButton.icon(
                    onPressed: () => setState(() => _rules.add('')),
                    icon: Icon(Icons.add_circle_outline, color: _gold, size: 18),
                    label: Text('Add Rule', style: TextStyle(color: _gold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._rules.asMap().entries.map((entry) {
                final index = entry.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: entry.value,
                          decoration: _inputDecoration('Rule ${index + 1}'),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          onChanged: (val) => _rules[index] = val,
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _rules.removeAt(index)),
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                      ),
                    ],
                  ),
                );
              }).toList(),
              
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
              onPressed: _isSaving ? null : _saveEvent,
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

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      keyboardType: keyboardType,
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
