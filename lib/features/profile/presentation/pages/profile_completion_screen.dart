import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neon_button.dart';
import '../providers/profile_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/profile_repository.dart';

class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends ConsumerState<ProfileCompletionScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _mobileFocus = FocusNode();
  
  String? _imageUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _mobileFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing data if any
    Future.microtask(() {
      final user = ref.read(profileProvider).user;
      if (user != null) {
        _nameController.text = user.name;
        _emailController.text = user.email;
        _mobileController.text = user.mobile;
        _imageUrl = user.profileImage;
      }
    });
  }

  void _updateProgress() {
    ref.read(profileProvider.notifier).updateProfile(
      name: _nameController.text,
      age: _ageController.text,
      email: _emailController.text,
      mobile: _mobileController.text,
      image: _imageUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete Your\nEvent Profile',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Help others recognize you and unlock networking features.',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              
              // Subtle Progress Section
              Consumer(
                builder: (context, ref, child) {
                  final completion = ref.watch(profileProvider.select((s) => s.user?.profileCompletion ?? 0.0));
                  final isComplete = completion >= 1.0;
                  
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isComplete 
                          ? AppColors.primary.withValues(alpha: 0.3) 
                          : Colors.white.withValues(alpha: 0.05)
                      ),
                      boxShadow: isComplete ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 20,
                          spreadRadius: 0,
                        )
                      ] : [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              (isComplete ? 'Profile completed' : 'Profile Strength').toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                                color: isComplete ? AppColors.primary : AppColors.textDim,
                              ),
                            ),
                            if (isComplete)
                              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16)
                            else
                              Text(
                                '${(completion * 100).toInt()}%',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textDim,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: completion,
                            backgroundColor: AppColors.background,
                            valueColor: AlwaysStoppedAnimation(
                              isComplete ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3)
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Image Upload Mock
              Center(
                child: GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    try {
                      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        final user = ref.read(profileProvider).user;
                        if (user != null) {
                          // Ideally show loading indicator here
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Uploading image...')),
                          );
                          // Pass keys/XFile directly - repository handles bytes
                          final url = await ref.read(profileRepositoryProvider).uploadProfileImage(
                            user.id, 
                            pickedFile,
                          );
                          
                          if (mounted) {
                            setState(() {
                              _imageUrl = url;
                            });
                            _updateProgress();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Image uploaded!')),
                            );
                          }
                        }
                      }
                    } catch (e) {
                      debugPrint('Error picking/uploading image: $e');
                      // Silent failure for UI - do not crash or show error
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.mainGradient,
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.surface,
                      backgroundImage: _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                      child: _imageUrl == null 
                        ? const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 30)
                        : null,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              _buildField(
                'Full Name', 
                _nameController, 
                Icons.person_outline,
                focusNode: _nameFocus,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              _buildField(
                'Date of Birth', 
                _ageController, 
                Icons.calendar_month_outlined, 
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppColors.primary,
                            onPrimary: Colors.white,
                            surface: AppColors.surface,
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (date != null && mounted) {
                    final age = DateTime.now().year - date.year;
                    _ageController.text = "${date.day}/${date.month}/${date.year} ($age years)";
                    _updateProgress();
                    // Move focus to next field after date selection
                    FocusScope.of(context).requestFocus(_emailFocus);
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildField(
                'Email Address', 
                _emailController, 
                Icons.alternate_email_rounded,
                focusNode: _emailFocus,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              _buildField(
                'Mobile Number', 
                _mobileController, 
                Icons.phone_android_outlined, 
                isNumber: true,
                focusNode: _mobileFocus,
                textInputAction: TextInputAction.done,
              ),
              
              const SizedBox(height: 60),
              
              Consumer(
                builder: (context, ref, child) {
                  final isComplete = ref.watch(profileProvider.select((s) => s.isComplete));
                  return Column(
                    children: [
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: isComplete ? 1.0 : 0.3,
                        child: NeonButton(
                          text: 'START EXPLORING',
                          onPressed: isComplete 
                            ? () => context.go('/home')
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please complete all required fields (Name, DOB, Email, Mobile)'),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: AppColors.surface,
                                  ),
                                );
                              },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: isComplete ? 0 : 0.5,
                          child: Text(
                            'Please fill all fields to continue',
                            style: GoogleFonts.inter(color: AppColors.textDim, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label, 
    TextEditingController controller, 
    IconData icon, {
    bool isNumber = false, 
    bool readOnly = false, 
    VoidCallback? onTap,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: AppColors.textDim,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            readOnly: readOnly,
            onTap: onTap,
            textInputAction: textInputAction,
            keyboardType: isNumber ? TextInputType.number : TextInputType.emailAddress,
            onChanged: (_) => _updateProgress(),
            style: GoogleFonts.inter(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
