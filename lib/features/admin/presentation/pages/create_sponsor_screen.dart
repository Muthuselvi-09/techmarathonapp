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

class CreateSponsorScreen extends ConsumerStatefulWidget {
  final Sponsor? sponsor;
  final String? preselectedEventId;

  const CreateSponsorScreen({super.key, this.sponsor, this.preselectedEventId});

  @override
  ConsumerState<CreateSponsorScreen> createState() => _CreateSponsorScreenState();
}

class _CreateSponsorScreenState extends ConsumerState<CreateSponsorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _companyController;
  late TextEditingController _roleController;
  late TextEditingController _taglineController;
  late TextEditingController _websiteController;
  late TextEditingController _descriptionController;
  late TextEditingController _boothLocationController;
  late TextEditingController _instagramController;
  late TextEditingController _linkedinController;
  late TextEditingController _youtubeController;

  String _tier = 'Gold';
  String? _selectedEventId;
  
  XFile? _logoImage;
  XFile? _bannerImage;
  String? _currentLogoUrl;
  String? _currentBannerUrl;
  
  bool _isSaving = false;
  bool _isUploadingMedia = false;

  late List<Map<String, dynamic>> _tempOffers;
  late List<Map<String, dynamic>> _tempProducts;
  late List<String> _tempMedia;

  final Color _gold = const Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.sponsor?.name);
    _companyController = TextEditingController(text: widget.sponsor?.company);
    _roleController = TextEditingController(text: widget.sponsor?.jobPosition);
    _taglineController = TextEditingController(text: widget.sponsor?.tagline);
    _websiteController = TextEditingController(text: widget.sponsor?.websiteUrl);
    _descriptionController = TextEditingController(text: widget.sponsor?.detailedDescription ?? widget.sponsor?.description);
    _boothLocationController = TextEditingController(text: widget.sponsor?.boothLocation);
    _instagramController = TextEditingController(text: widget.sponsor?.instagramUrl);
    _linkedinController = TextEditingController(text: widget.sponsor?.linkedinUrl);
    _youtubeController = TextEditingController(text: widget.sponsor?.youtubeUrl);

    _tier = widget.sponsor?.tier ?? 'Gold';
    _selectedEventId = widget.sponsor?.eventId ?? widget.preselectedEventId;
    _currentLogoUrl = widget.sponsor?.logoUrl;
    _currentBannerUrl = widget.sponsor?.bannerUrl;

    _tempOffers = List.from(widget.sponsor?.offers ?? []);
    _tempProducts = List.from(widget.sponsor?.products ?? []);
    _tempMedia = List.from(widget.sponsor?.media ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _roleController.dispose();
    _taglineController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    _boothLocationController.dispose();
    _instagramController.dispose();
    _linkedinController.dispose();
    _youtubeController.dispose();
    super.dispose();
  }

  Future<void> _saveSponsor() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);

    try {
      final optimisticSponsor = Sponsor(
        id: widget.sponsor?.id ?? '',
        name: _nameController.text.trim(),
        company: _companyController.text.trim(),
        jobPosition: _roleController.text.trim(),
        tier: _tier,
        logoUrl: _currentLogoUrl ?? '',
        bannerUrl: _currentBannerUrl ?? '',
        tagline: _taglineController.text.trim(),
        websiteUrl: _websiteController.text.trim(),
        detailedDescription: _descriptionController.text.trim(),
        boothLocation: _boothLocationController.text.trim(),
        instagramUrl: _instagramController.text.trim(),
        linkedinUrl: _linkedinController.text.trim(),
        youtubeUrl: _youtubeController.text.trim(),
        eventId: _selectedEventId ?? '',
        offers: _tempOffers,
        products: _tempProducts,
        media: _tempMedia,
      );

      if (mounted) context.pop();

      await ref.read(adminRepositoryProvider).saveSponsor(
        optimisticSponsor,
        eventId: _selectedEventId,
        isNew: widget.sponsor == null,
        logoFile: _logoImage,
        bannerFile: _bannerImage,
      );

    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
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
          widget.sponsor == null ? 'Add Sponsor' : 'Edit Sponsor',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _isSaving ? null : _saveSponsor,
              style: TextButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              ),
              child: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) 
                  : Text('Save', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event & Tier
              StreamBuilder<List<CodingEvent>>(
                stream: ref.watch(adminRepositoryProvider).watchEvents(),
                builder: (context, snapshot) {
                  final events = snapshot.data ?? [];
                  return DropdownButtonFormField<String>(
                    value: (events.any((e) => e.id == _selectedEventId)) ? _selectedEventId : null,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Select Event'),
                    items: events.map((e) => DropdownMenuItem(
                      value: e.id,
                      child: Text(e.name, style: const TextStyle(color: Colors.white)),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedEventId = val),
                  );
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _tier,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Sponsorship Tier'),
                items: ['Platinum', 'Gold', 'Silver', 'Bronze']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Colors.white))))
                    .toList(),
                onChanged: (val) => setState(() => _tier = val!),
              ),
              const SizedBox(height: 24),

              // Basic Info
              _buildSectionHeader('Company Details'),
              Row(
                children: [
                   // Logo Picker
                   Expanded(
                     child: GestureDetector(
                       onTap: () async {
                         final picker = ImagePicker();
                         final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                         if (image != null) setState(() => _logoImage = image);
                       },
                       child: Container(
                         height: 100,
                         decoration: BoxDecoration(
                           color: Colors.white12,
                           borderRadius: BorderRadius.circular(12),
                           image: _logoImage != null 
                              ? DecorationImage(
                                   image: kIsWeb 
                                      ? NetworkImage(_logoImage!.path) 
                                      : FileImage(File(_logoImage!.path)) as ImageProvider,
                                   fit: BoxFit.contain
                                )
                              : (_currentLogoUrl != null && _currentLogoUrl!.isNotEmpty)
                                ? DecorationImage(image: NetworkImage(_currentLogoUrl!), fit: BoxFit.contain)
                                : null,
                           border: Border.all(color: Colors.white24),
                         ),
                         child: _logoImage == null && (_currentLogoUrl == null || _currentLogoUrl!.isEmpty)
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, color: Colors.white54),
                                  Text('Logo', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                ],
                              )
                            : null,
                       ),
                     ),
                   ),
                   const SizedBox(width: 16),
                   // Banner Picker
                   Expanded(
                     flex: 2,
                     child: GestureDetector(
                       onTap: () async {
                         final picker = ImagePicker();
                         final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                         if (image != null) setState(() => _bannerImage = image);
                       },
                       child: Container(
                         height: 100,
                         decoration: BoxDecoration(
                           color: Colors.white12,
                           borderRadius: BorderRadius.circular(12),
                           image: _bannerImage != null 
                              ? DecorationImage(
                                   image: kIsWeb 
                                      ? NetworkImage(_bannerImage!.path) 
                                      : FileImage(File(_bannerImage!.path)) as ImageProvider,
                                   fit: BoxFit.cover
                                )
                              : (_currentBannerUrl != null && _currentBannerUrl!.isNotEmpty)
                                ? DecorationImage(image: NetworkImage(_currentBannerUrl!), fit: BoxFit.cover)
                                : null,
                           border: Border.all(color: Colors.white24),
                         ),
                         child: _bannerImage == null && (_currentBannerUrl == null || _currentBannerUrl!.isEmpty)
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image, color: Colors.white54),
                                  Text('Banner', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                ],
                              )
                            : null,
                       ),
                     ),
                   ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(_nameController, 'Sponsor Name', validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              _buildTextField(_taglineController, 'Tagline'),
              const SizedBox(height: 16),
              _buildTextField(_companyController, 'Company Name'),
              const SizedBox(height: 16),
              _buildTextField(_roleController, 'Role / Position'),
              const SizedBox(height: 16),
              _buildTextField(_descriptionController, 'Detailed Description', maxLines: 4),
              const SizedBox(height: 16),
              _buildTextField(_boothLocationController, 'Booth Location (e.g. B12)'),
              const SizedBox(height: 16),
              _buildTextField(_websiteController, 'Website URL'),
              
              const SizedBox(height: 32),

              // Offers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader('Offers & Deals'),
                  TextButton.icon(
                    onPressed: () => _showAddOfferDialog(),
                    icon: Icon(Icons.add_circle_outline, size: 16, color: _gold),
                    label: Text('Add Offer', style: TextStyle(color: _gold)),
                  ),
                ],
              ),
              ..._tempOffers.asMap().entries.map((entry) {
                final i = entry.key;
                final offer = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(offer['title'] ?? 'No Title', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text(offer['description'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.deepOrange, size: 20),
                        onPressed: () => setState(() => _tempOffers.removeAt(i)),
                      ),
                    ],
                  ),
                );
              }),
              
              const SizedBox(height: 24),

              // Products
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader('Products & Services'),
                  TextButton.icon(
                    onPressed: () => _showAddProductDialog(),
                    icon: Icon(Icons.add_circle_outline, size: 16, color: _gold),
                    label: Text('Add Product', style: TextStyle(color: _gold)),
                  ),
                ],
              ),
              ..._tempProducts.asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      if (p['image'] != null && p['image'].isNotEmpty)
                         Container(
                           width: 40, height: 40,
                           margin: const EdgeInsets.only(right: 12),
                           decoration: BoxDecoration(
                             borderRadius: BorderRadius.circular(8),
                             image: DecorationImage(image: NetworkImage(p['image']), fit: BoxFit.cover),
                           ),
                         ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['name'] ?? 'Product', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.deepOrange, size: 20),
                        onPressed: () => setState(() => _tempProducts.removeAt(i)),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),
              
              // Media Gallery
               Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader('Media Gallery'),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._tempMedia.asMap().entries.map((entry) {
                    final i = entry.key;
                    return Stack(
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(image: NetworkImage(entry.value), fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          right: -4, top: -4,
                          child: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                            onPressed: () => setState(() => _tempMedia.removeAt(i)),
                          ),
                        ),
                      ],
                    );
                  }),
                  GestureDetector(
                    onTap: _isUploadingMedia ? null : () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                      if (image != null) {
                        setState(() => _isUploadingMedia = true);
                        try {
                           final bytes = await image.readAsBytes();
                           // Assume uploadToCloudinary is available in repository
                           final url = await ref.read(adminRepositoryProvider).uploadToCloudinary(data: bytes, folder: 'sponsors/media');
                           setState(() {
                             _tempMedia.add(url);
                             _isUploadingMedia = false;
                           });
                        } catch (e) {
                           setState(() => _isUploadingMedia = false);
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
                        }
                      }
                    },
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24, style: BorderStyle.solid),
                      ),
                      child: _isUploadingMedia
                        ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD700)))
                        : const Icon(Icons.add_a_photo, color: Colors.white38),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddOfferDialog() {
    final titleC = TextEditingController();
    final descC = TextEditingController();
    final codeC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Add Offer', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogTextField(titleC, 'Title'),
            const SizedBox(height: 12),
            _buildDialogTextField(descC, 'Description'),
            const SizedBox(height: 12),
            _buildDialogTextField(codeC, 'Promo Code'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => _tempOffers.add({'title': titleC.text, 'description': descC.text, 'code': codeC.text}));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.black),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog() {
    final nameC = TextEditingController();
    final descC = TextEditingController();
    XFile? selectedImage;
    bool uploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Add Product', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                   final picker = ImagePicker();
                   final img = await picker.pickImage(source: ImageSource.gallery);
                   if (img != null) setDialogState(() => selectedImage = img);
                },
                child: Container(
                  height: 80, width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(8),
                    image: selectedImage != null 
                        ? DecorationImage(
                             image: kIsWeb 
                                ? NetworkImage(selectedImage!.path) 
                                : FileImage(File(selectedImage!.path)) as ImageProvider,
                             fit: BoxFit.cover
                          )
                        : null,
                  ),
                  child: selectedImage == null ? const Icon(Icons.add_photo_alternate, color: Colors.white54) : null,
                ),
              ),
              const SizedBox(height: 12),
              _buildDialogTextField(nameC, 'Name'),
              const SizedBox(height: 12),
              _buildDialogTextField(descC, 'Short Description'),
              if (uploading) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator(color: Color(0xFFFFD700))),
            ],
          ),
          actions: [
            if (!uploading) TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: uploading ? null : () async {
                 if (nameC.text.isEmpty) return;
                 String url = '';
                 if (selectedImage != null) {
                    setDialogState(() => uploading = true);
                    try {
                      final bytes = await selectedImage!.readAsBytes();
                      url = await ref.read(adminRepositoryProvider).uploadToCloudinary(data: bytes, folder: 'sponsors/products');
                    } catch (e) {
                      setDialogState(() => uploading = false);
                      return;
                    }
                 }
                 setState(() => _tempProducts.add({'name': nameC.text, 'desc': descC.text, 'image': url}));
                 if (mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.black),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogTextField(TextEditingController c, String label) {
    return TextField(
      controller: c, 
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
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
