import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/event_widgets.dart';

class EventLoginScreen extends StatefulWidget {
  const EventLoginScreen({super.key});

  @override
  State<EventLoginScreen> createState() => _EventLoginScreenState();
}

class _EventLoginScreenState extends State<EventLoginScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandHeader(showZhaCommerce: true),
              const Spacer(),
              Text(
                'Join the\nTech Marathon',
                style: GoogleFonts.outfit(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Enter your email to access your pass and connect with participants.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),
              _buildTextField(),
              const SizedBox(height: 32),
              _buildLoginButton(context),
              const Spacer(),
              Center(
                child: Text(
                  'By joining, you agree to our Terms of Service.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textDim),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        controller: _emailController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Email Address',
          hintStyle: TextStyle(color: AppColors.textDim),
          border: InputBorder.none,
          icon: const Icon(Icons.alternate_email_rounded, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: () => context.go('/event-home'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: Text(
          'CONTINUE',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
      ),
    );
  }
}
