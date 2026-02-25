import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tech_marathon_app/core/theme/app_colors.dart';
import 'package:tech_marathon_app/features/admin/data/admin_repository.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AddImageFeedScreen extends ConsumerStatefulWidget {
  final String eventId;
  const AddImageFeedScreen({super.key, required this.eventId});

  @override
  ConsumerState<AddImageFeedScreen> createState() => _AddImageFeedScreenState();
}

class _AddImageFeedScreenState extends ConsumerState<AddImageFeedScreen> {
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _extraController = TextEditingController();
  final _messageController = TextEditingController();
  XFile? _selectedImage;
  bool _isUploading = false;
  String _selectedCategory = 'Certificate';

  final List<String> _categories = [
    'Certificate',
    'Chief Guest',
    'Sponsors',
    'Team Introduction',
    'Invitation'
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() => _isUploading = true);

    try {
      final adminRepo = ref.read(adminRepositoryProvider);
      
      // Upload to Cloudinary using bytes for Web compatibility
      final bytes = await _selectedImage!.readAsBytes();
      final imageUrl = await adminRepo.uploadToCloudinary(
        data: bytes,
        folder: 'live_feed_images',
      );

      // Collect data based on category
      final Map<String, dynamic> templateData = {
        'category': _selectedCategory,
      };

      switch (_selectedCategory) {
        case 'Certificate':
          templateData['name'] = _nameController.text.trim();
          templateData['title'] = _titleController.text.trim();
          templateData['message'] = _messageController.text.trim();
          break;
        case 'Chief Guest':
          templateData['name'] = _nameController.text.trim();
          templateData['message'] = _extraController.text.trim();
          break;
        case 'Sponsors':
          templateData['name'] = _nameController.text.trim();
          templateData['message'] = _extraController.text.trim();
          break;
        case 'Team Introduction':
          templateData['name'] = _nameController.text.trim();
          templateData['message'] = _extraController.text.trim();
          break;
        case 'Invitation':
          templateData['title'] = _titleController.text.trim();
          templateData['message'] = _extraController.text.trim();
          break;
      }

      // Save LiveFeedItem to Firestore
      final item = LiveFeedItem(
        id: '',
        eventId: widget.eventId,
        type: 'template',
        contentUrl: imageUrl,
        templateData: templateData,
      );

      await adminRepo.saveLiveFeedItem(item);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update posted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String _getHintText() {
    switch (_selectedCategory) {
      case 'Certificate':
        return 'What is this certificate for? Add details...';
      case 'Chief Guest':
        return 'Describe the chief guest and their contribution...';
      case 'Sponsors':
        return 'Highlight the sponsor and their support...';
      case 'Team Introduction':
        return 'Introduce the team members shown here...';
      case 'Invitation':
        return 'Add invitation details and special notes...';
      default:
        return 'Share some thoughts about this update...';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Using AppColors.saasPrimary directly

    return Scaffold(
      backgroundColor: AppColors.saasSidebarBg,
      appBar: AppBar(
        backgroundColor: AppColors.saasSidebarBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'POST IMAGE UPDATE',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 18,
          ),
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        color: AppColors.saasSidebarBg,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Selection
              Text(
                'SELECT CATEGORY',
                style: GoogleFonts.outfit(
                  color: Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedCategory = cat;
                        _nameController.clear();
                        _titleController.clear();
                        _extraController.clear();
                        _messageController.clear();
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.saasPrimary : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected ? null : Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          boxShadow: isSelected ? [
                            BoxShadow(color: AppColors.saasPrimary.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: -5)
                          ] : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          cat,
                          style: GoogleFonts.outfit(
                            color: isSelected ? Colors.black : Colors.white70,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 48),

              // Image Picker Area
              GestureDetector(
                onTap: _isUploading ? null : _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: _selectedImage != null ? AppColors.saasPrimary : Colors.white.withValues(alpha: 0.08),
                      style: _selectedImage != null ? BorderStyle.solid : BorderStyle.solid,
                      width: 1,
                    ),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              kIsWeb 
                                ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                                : Image.file(io.File(_selectedImage!.path), fit: BoxFit.cover),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 20,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.refresh_rounded, color: AppColors.saasPrimary, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Tap to change image',
                                        style: GoogleFonts.outfit(color: AppColors.saasPrimary, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.saasPrimary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_photo_alternate_rounded, color: AppColors.saasPrimary, size: 40),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Select Design from Gallery',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Upload your custom JPG, PNG designs',
                              style: TextStyle(color: Colors.white24, fontSize: 13),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 40),

              // Optional Caption
              // Dynamic Fields
              Text(
                'DETAILS FOR ${_selectedCategory.toUpperCase()}',
                style: GoogleFonts.outfit(
                  color: Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 24),
              
              ..._buildCategoryFields(AppColors.saasPrimary),

              const SizedBox(height: 56),

              // Action Button
              Center(
                child: Container(
                  width: 280,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: AppColors.saasGradient,
                    boxShadow: AppColors.saasShadow,
                  ),
                  child: ElevatedButton(
                    onPressed: (_isUploading || _selectedImage == null) ? null : _uploadImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          )
                        : Text(
                            'POST UPDATE',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Colors.white),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  List<Widget> _buildCategoryFields(Color primary) {
    switch (_selectedCategory) {
      case 'Certificate':
        return [
          _buildField(controller: _nameController, hint: 'Recipient Name (e.g. John Doe)', icon: Icons.person_outline),
          const SizedBox(height: 16),
          _buildField(controller: _titleController, hint: 'Achievement Title (e.g. Winner - Code Hack)', icon: Icons.workspace_premium_outlined),
          const SizedBox(height: 16),
          _buildField(controller: _messageController, hint: 'Special Message (e.g. For outstanding performance)', icon: Icons.chat_bubble_outline, maxLines: 3),
        ];
      case 'Chief Guest':
        return [
          _buildField(controller: _nameController, hint: 'Chief Guest Name', icon: Icons.person_outline),
          const SizedBox(height: 16),
          _buildField(controller: _extraController, hint: 'Bio or Topic (e.g. CEO of TechCorp / AI Future)', icon: Icons.info_outline, maxLines: 2),
        ];
      case 'Sponsors':
        return [
          _buildField(controller: _nameController, hint: 'Company Name', icon: Icons.business_outlined),
          const SizedBox(height: 16),
          _buildField(controller: _extraController, hint: 'Support Level (e.g. Platinum Sponsor)', icon: Icons.star_border_rounded),
        ];
      case 'Team Introduction':
        return [
          _buildField(controller: _nameController, hint: 'Team/Department Name', icon: Icons.groups_outlined),
          const SizedBox(height: 16),
          _buildField(controller: _extraController, hint: 'Team Members (e.g. Alice, Bob, Charlie)', icon: Icons.people_outline, maxLines: 3),
        ];
      case 'Invitation':
        return [
          _buildField(controller: _titleController, hint: 'Event or Session Title', icon: Icons.event_outlined),
          const SizedBox(height: 16),
          _buildField(controller: _extraController, hint: 'Venue & Time (e.g. Ballroom / 10 AM)', icon: Icons.location_on_outlined),
        ];
      default:
        return [];
    }
  }

  Widget _buildField({required TextEditingController controller, required String hint, required IconData icon, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: controller,
        enabled: !_isUploading,
        maxLines: maxLines,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white24, size: 20),
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 14),
          contentPadding: const EdgeInsets.all(20),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
