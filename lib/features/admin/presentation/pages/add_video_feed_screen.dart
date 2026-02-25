import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tech_marathon_app/core/theme/app_colors.dart';
import 'package:tech_marathon_app/features/admin/data/admin_repository.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AddVideoFeedScreen extends ConsumerStatefulWidget {
  final String eventId;
  const AddVideoFeedScreen({super.key, required this.eventId});

  @override
  ConsumerState<AddVideoFeedScreen> createState() => _AddVideoFeedScreenState();
}

class _AddVideoFeedScreenState extends ConsumerState<AddVideoFeedScreen> {
  final _titleController = TextEditingController();
  XFile? _selectedVideo;
  bool _isUploading = false;
  double _uploadProgress = 0;

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedVideo = video;
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (_selectedVideo == null) return;
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a caption')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final adminRepo = ref.read(adminRepositoryProvider);
      
      // Upload to Cloudinary using bytes for Web compatibility
      final bytes = await _selectedVideo!.readAsBytes();
      final videoUrl = await adminRepo.uploadToCloudinary(
        data: bytes,
        resourceType: 'video',
        folder: 'live_feed_videos',
      );

      // Save LiveFeedItem to Firestore
      final item = LiveFeedItem(
        id: '',
        eventId: widget.eventId,
        type: 'video',
        contentUrl: videoUrl,
        templateData: {
          'title': _titleController.text.trim(),
        },
      );

      await adminRepo.saveLiveFeedItem(item);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video posted successfully!')),
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

  @override
  Widget build(BuildContext context) {
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
          'POST VIDEO UPDATE',
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
              // Premium Header Hint
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.codingRimPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.codingRimPrimary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.codingRimPrimary, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'PREMIUM VIDEO UPDATE',
                      style: GoogleFonts.outfit(
                        color: AppColors.codingRimPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Broadcast live moments\nto your audience',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 48),
              
              // Video Picker Area (Glassmorphic)
              GestureDetector(
                onTap: _isUploading ? null : _pickVideo,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: _selectedVideo != null ? AppColors.codingRimPrimary : Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                    boxShadow: _selectedVideo != null ? [
                      BoxShadow(
                        color: AppColors.codingRimPrimary.withValues(alpha: 0.1),
                        blurRadius: 30,
                        spreadRadius: -10,
                      )
                    ] : [],
                  ),
                  child: _selectedVideo != null
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppColors.codingRimPrimary, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  _selectedVideo!.name,
                                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Tap to change video',
                                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.codingRimPrimary.withValues(alpha: 0.2), Colors.transparent],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_a_photo_rounded, color: AppColors.codingRimPrimary, size: 32),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Select Video',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'MP4, MOV up to 2 minutes',
                              style: TextStyle(color: Colors.white24, fontSize: 13),
                            ),
                          ],
                        ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Caption Area
              Text(
                'WHAT IS HAPPENING?',
                style: GoogleFonts.outfit(
                  color: Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: TextField(
                  controller: _titleController,
                  enabled: !_isUploading,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Add a descriptive caption for your video update...',
                    hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 14),
                    contentPadding: const EdgeInsets.all(24),
                    border: InputBorder.none,
                  ),
                ),
              ),
              
              const SizedBox(height: 56),
              
              // Action Button (Premium Glow)
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
                    onPressed: (_isUploading || _selectedVideo == null) ? null : _uploadVideo,
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
                            'PUBLISH UPDATE',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Colors.white),
                          ),
                  ),
                ),
              ),

              if (_isUploading) ...[
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Transmitting high-quality video...',
                    style: GoogleFonts.inter(color: AppColors.codingRimPrimary.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

