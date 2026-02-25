import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/home/domain/event_models.dart';
import '../../data/admin_repository.dart';

class CreateSpeakerScreen extends ConsumerStatefulWidget {
  final Speaker? speaker;
  final String? preselectedEventId;

  const CreateSpeakerScreen({super.key, this.speaker, this.preselectedEventId});

  @override
  ConsumerState<CreateSpeakerScreen> createState() => _CreateSpeakerScreenState();
}

class _CreateSpeakerScreenState extends ConsumerState<CreateSpeakerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _topicController;
  late TextEditingController _companyController;
  late TextEditingController _bioController;
  late TextEditingController _linkedinController;
  late TextEditingController _roleController;

  String? _selectedEventId;
  XFile? _selectedImage;
  String? _currentPhotoUrl;
  bool _isSaving = false;

  final Color _gold = const Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.speaker?.name);
    _topicController = TextEditingController(text: widget.speaker?.topic);
    _companyController = TextEditingController(text: widget.speaker?.company);
    _bioController = TextEditingController(text: widget.speaker?.bio);
    _linkedinController = TextEditingController(text: widget.speaker?.linkedinUrl);
    _roleController = TextEditingController(text: widget.speaker?.role ?? 'Speaker');
    
    _selectedEventId = widget.speaker?.eventId ?? widget.preselectedEventId;
    _currentPhotoUrl = widget.speaker?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _topicController.dispose();
    _companyController.dispose();
    _bioController.dispose();
    _linkedinController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _saveSpeaker() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);

    try {
      final optimisticSpeaker = Speaker(
        id: widget.speaker?.id ?? '', 
        name: _nameController.text.trim(),
        topic: _topicController.text.trim(),
        company: _companyController.text.trim(),
        imageUrl: _currentPhotoUrl ?? '',
        bio: _bioController.text.trim(),
        role: _roleController.text.trim(),
        linkedinUrl: _linkedinController.text.trim(),
        eventId: _selectedEventId ?? '',
      );

      if (mounted) context.pop();

      await ref.read(adminRepositoryProvider).saveSpeaker(
        optimisticSpeaker,
        eventId: _selectedEventId,
        isNew: widget.speaker == null,
        imageFile: _selectedImage,
      );

    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving speaker: $e')));
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
          widget.speaker == null ? 'Add Speaker' : 'Edit Speaker',
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
              // Photo Upload
              Center(
                child: GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                    if (image != null) {
                      setState(() => _selectedImage = image);
                    }
                  },
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      shape: BoxShape.circle,
                      image: _selectedImage != null 
                        ? DecorationImage(
                            image: kIsWeb 
                                ? NetworkImage(_selectedImage!.path) 
                                : FileImage(File(_selectedImage!.path)) as ImageProvider,
                            fit: BoxFit.cover
                          )
                        : (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty)
                          ? DecorationImage(image: NetworkImage(_currentPhotoUrl!), fit: BoxFit.cover)
                          : null,
                      border: Border.all(color: _gold.withValues(alpha: 0.5), width: 2),
                    ),
                    child: _selectedImage == null && (_currentPhotoUrl == null || _currentPhotoUrl!.isEmpty)
                      ? const Icon(Icons.add_a_photo, color: Colors.white54, size: 40)
                      : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text('Tap to upload photo', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
              ),
              const SizedBox(height: 32),

              // Event Selection
              const Text('Assigned Event', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              StreamBuilder<List<CodingEvent>>(
                stream: ref.watch(adminRepositoryProvider).watchEvents(),
                builder: (context, snapshot) {
                  return DropdownButtonFormField<String>(
                    value: (snapshot.data ?? []).any((e) => e.id == _selectedEventId) ? _selectedEventId : null,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Select Event (Optional)'),
                    items: (snapshot.data ?? []).map((e) => DropdownMenuItem(
                      value: e.id,
                      child: Text(e.name, style: const TextStyle(color: Colors.white)),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedEventId = val),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Info Fields
              _buildSectionHeader('Speaker Details'),
              _buildTextField(_nameController, 'Full Name', validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              _buildTextField(_roleController, 'Role (e.g. Keynote Speaker)'),
              const SizedBox(height: 16),
              _buildTextField(_topicController, 'Topic'),
              const SizedBox(height: 16),
              _buildTextField(_companyController, 'Company / Organization'),
              const SizedBox(height: 16),
              _buildTextField(_linkedinController, 'LinkedIn URL (Optional)'),
              const SizedBox(height: 24),

              _buildSectionHeader('Bio'),
              _buildTextField(_bioController, 'Biography', maxLines: 5),
              
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
              onPressed: _isSaving ? null : _saveSpeaker,
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
