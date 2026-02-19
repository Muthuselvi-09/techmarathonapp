import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tech_marathon_app/core/theme/app_colors.dart';
import 'package:tech_marathon_app/features/admin/data/admin_repository.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LiveFeedTemplateEditor extends ConsumerStatefulWidget {
  final String eventId;
  const LiveFeedTemplateEditor({super.key, required this.eventId});

  @override
  ConsumerState<LiveFeedTemplateEditor> createState() => _LiveFeedTemplateEditorState();
}

class _LiveFeedTemplateEditorState extends ConsumerState<LiveFeedTemplateEditor> {
  String _templateType = 'certificate';
  final _controllers = <String, TextEditingController>{
    'title': TextEditingController(),
    'name': TextEditingController(),
    'message': TextEditingController(),
  };

  XFile? _selectedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _resetControllers();
  }

  void _resetControllers() {
    _controllers['title']?.text = _getDefaultTitle();
    _controllers['name']?.text = _getDefaultName();
    _controllers['message']?.text = _getDefaultMessage();
    _selectedImage = null;
  }

  String _getDefaultTitle() {
    switch (_templateType) {
      case 'certificate': return 'CERTIFICATE OF APPRECIATION';
      case 'invite': return 'OFFICIAL INVITATION';
      case 'intro': return 'PLATFORM HIGHLIGHTS';
      default: return '';
    }
  }

  String _getDefaultName() {
    switch (_templateType) {
      case 'certificate': return 'John Doe';
      case 'guest': return 'Dr. Sarah Wilson';
      case 'sponsor': return 'TechCorp Solutions';
      default: return '';
    }
  }

  String _getDefaultMessage() {
    switch (_templateType) {
      case 'certificate': return 'Outstanding performance in the marathon';
      case 'guest': return 'Keynote Speaker & AI Specialist';
      case 'invite': return 'Grand Ballroom, 10:00 AM';
      case 'sponsor': return 'Official Silver Partner';
      case 'intro': return 'Register now to unlock all event features';
      default: return '';
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _saveTemplate() async {
    setState(() => _isUploading = true);
    try {
      final adminRepo = ref.read(adminRepositoryProvider);
      String? imageUrl;
      
      if (_selectedImage != null) {
        imageUrl = await adminRepo.uploadToCloudinary(
          filePath: _selectedImage!.path,
          folder: 'live_feed_templates',
        );
      }

      final item = LiveFeedItem(
        id: '',
        eventId: widget.eventId,
        type: 'template',
        templateType: _templateType,
        contentUrl: imageUrl,
        templateData: {
          'title': _controllers['title']?.text.trim(),
          'name': _controllers['name']?.text.trim(),
          'message': _controllers['message']?.text.trim(),
        },
      );

      await adminRepo.saveLiveFeedItem(item);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feed update posted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'TEMPLATE EDITOR',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        actions: [
          if (_isUploading)
            const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))))
          else
            TextButton(
              onPressed: _saveTemplate,
              child: Text('POST', style: GoogleFonts.outfit(color: AppColors.codingRimPrimary, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
        ],
      ),
      body: Row(
        children: [
          // Canvas Side (Preview)
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Text(
                          'PREVIEW',
                          style: GoogleFonts.outfit(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 12),
                        ),
                        const SizedBox(height: 40),
                        _buildCanvasPreview(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Controls Side
          Container(
            width: 350,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CUSTOMIZE',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 32),
                
                // Template Selector
                _controlLabel('Select Template'),
                const SizedBox(height: 12),
                _buildTemplateSelector(),
                
                const SizedBox(height: 32),
                const Divider(color: Colors.white10),
                const SizedBox(height: 32),
                
                // Dynamic Fields
                Expanded(
                  child: ListView(
                    children: [
                      if (_templateType != 'guest' && _templateType != 'sponsor') ...[
                        _controlLabel('Headline'),
                        const SizedBox(height: 12),
                        _buildTextField(_controllers['title']!, 'Enter headline...'),
                        const SizedBox(height: 24),
                      ],
                      if (_templateType != 'invite' && _templateType != 'intro') ...[
                        _controlLabel(_templateType == 'sponsor' ? 'Company Name' : 'Recipient Name'),
                        const SizedBox(height: 12),
                        _buildTextField(_controllers['name']!, 'Enter name...'),
                        const SizedBox(height: 24),
                      ],
                      _controlLabel(_templateType == 'invite' ? 'Venue & Time' : 'Description'),
                      const SizedBox(height: 12),
                      _buildTextField(_controllers['message']!, 'Enter details...', maxLines: 3),
                      const SizedBox(height: 32),
                      
                      // Media Picker
                      _controlLabel('Background/Profile Image'),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(File(_selectedImage!.path), fit: BoxFit.cover, width: double.infinity),
                                )
                              : const Center(child: Icon(Icons.add_photo_alternate_outlined, color: Colors.white24, size: 32)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlLabel(String label) {
    return Text(label.toUpperCase(), style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2));
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white12),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildTemplateSelector() {
    final templates = ['certificate', 'guest', 'invite', 'sponsor', 'intro'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: templates.map((t) {
          bool isSelected = _templateType == t;
          return GestureDetector(
            onTap: () {
              setState(() {
                _templateType = t;
                _resetControllers();
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.codingRimPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                t.toUpperCase(),
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCanvasPreview() {
    return Container(
      width: 450,
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: AppColors.codingRimPrimary.withValues(alpha: 0.1), blurRadius: 100, spreadRadius: 10)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: AspectRatio(
          aspectRatio: 1,
          child: _getTemplateWidget(),
        ),
      ),
    );
  }

  Widget _getTemplateWidget() {
    switch (_templateType) {
      case 'certificate': return _certificatePreview();
      case 'guest': return _guestPreview();
      case 'invite': return _invitePreview();
      case 'sponsor': return _sponsorPreview();
      case 'intro': return _introPreview();
      default: return Container();
    }
  }

  Widget _certificatePreview() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.codingRimPrimary, Color(0xFFD4AF37)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium_rounded, size: 80, color: Colors.black),
          const SizedBox(height: 32),
          Text(
            _controllers['title']!.text,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 4),
          ),
          const Spacer(),
          Text(
            _controllers['name']!.text,
            style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 32),
          ),
          const SizedBox(height: 16),
          Text(
            _controllers['message']!.text,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.black.withValues(alpha: 0.7), fontSize: 16),
          ),
          const Spacer(),
          const Divider(color: Colors.black26),
          const SizedBox(height: 16),
          const Text('OFFICIAL EVENT RECOGNITION', style: TextStyle(color: Colors.black38, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _guestPreview() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white10,
              image: _selectedImage != null ? DecorationImage(image: FileImage(File(_selectedImage!.path)), fit: BoxFit.cover) : null,
            ),
            child: _selectedImage == null ? const Icon(Icons.person_rounded, size: 100, color: Colors.white10) : null,
          ),
        ),
        Expanded(
          child: Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CHIEF GUEST', style: GoogleFonts.outfit(color: AppColors.codingRimPrimary, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 10)),
                const SizedBox(height: 4),
                Text(_controllers['name']!.text, style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text(_controllers['message']!.text, style: GoogleFonts.inter(color: Colors.white38, fontSize: 14)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _invitePreview() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.codingRimPrimary.withValues(alpha: 0.2), width: 2),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mail_rounded, size: 60, color: AppColors.codingRimPrimary),
          const SizedBox(height: 32),
          Text(_controllers['title']!.text, style: GoogleFonts.outfit(color: AppColors.codingRimPrimary, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 4)),
          const SizedBox(height: 24),
          const Text('WARMLY INVITES YOU TO JOIN US', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2)),
          const SizedBox(height: 40),
          Text('TECH MARATHON 2026', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(border: Border.all(color: Colors.white10)),
            child: Text(_controllers['message']!.text, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _sponsorPreview() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('POWERED BY', style: GoogleFonts.outfit(color: Colors.black26, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 4)),
          const Spacer(),
          if (_selectedImage != null)
            Image.file(File(_selectedImage!.path), height: 120, fit: BoxFit.contain)
          else
            const Icon(Icons.business_rounded, size: 100, color: Colors.black12),
          const Spacer(),
          Text(_controllers['name']!.text, style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 28)),
          const SizedBox(height: 8),
          Text(_controllers['message']!.text, style: GoogleFonts.inter(color: Colors.black45, fontSize: 14)),
          const Spacer(),
          const Text('THANK YOU FOR YOUR PARTNERSHIP', style: TextStyle(color: AppColors.codingRimPrimary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _introPreview() {
    return Stack(
      children: [
        if (_selectedImage != null)
          Positioned.fill(child: Image.file(File(_selectedImage!.path), fit: BoxFit.cover)),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(padding: const EdgeInsets.all(4), color: AppColors.codingRimPrimary, child: const Icon(Icons.bolt, size: 20, color: Colors.black)),
              const SizedBox(height: 16),
              Text(_controllers['title']!.text, style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1.1)),
              const SizedBox(height: 16),
              Text(_controllers['message']!.text, style: GoogleFonts.inter(color: Colors.white70, fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }
}
