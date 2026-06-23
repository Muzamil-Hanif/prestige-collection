import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../utils/responsive.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _picker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  UserModel? _profile;
  String? _selectedImageDataUri;
  XFile? _selectedImageFile;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await ApiService.getProfile();
      if (!mounted) return;
      debugPrint('Profile photo from API: ${profile.profilePhoto}');

      setState(() {
        _profile = profile;
        _fullNameController.text = profile.fullName;
        _selectedImageDataUri = null;
        _selectedImageFile = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _openPhotoPickerOptions() async {
    final selection = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Update Profile Photo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Colors.white),
                title: const Text(
                  'Take a photo',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Colors.white),
                title: const Text(
                  'Add from gallery',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selection == null) return;

    try {
      final picked = await _picker.pickImage(
        source: selection,
        imageQuality: 40,
        maxWidth: 600,
        maxHeight: 600,
      );

      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImageFile = picked;
        final mime = picked.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
        _selectedImageDataUri = 'data:$mime;base64,${base64Encode(bytes)}';
      });

      _showThemedToast(
        'Photo selected. It will preview here.',
        isError: false,
      );
    } catch (e) {
      if (!mounted) return;
      _showThemedToast(
        'Unable to pick image: ${e.toString()}',
        isError: true,
      );
    }
  }

  void _showThemedToast(String message, {required bool isError}) {
    final messenger = ScaffoldMessenger.of(context);
    final cs = Theme.of(context).colorScheme;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          elevation: 4,
          duration: const Duration(seconds: 3),
          backgroundColor: isError ? const Color(0xFFEF4444) : cs.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
                color: isError ? Colors.white : cs.secondary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isSaving) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      final hasPasswordInput = _currentPasswordController.text.isNotEmpty ||
          _newPasswordController.text.isNotEmpty ||
          _confirmPasswordController.text.isNotEmpty;
      final hasNameChange =
          _fullNameController.text.trim() != (_profile?.fullName.trim() ?? '');
      final hasPhotoChange = _selectedImageFile != null;

      UserModel? updatedProfile = _profile;

      if (hasNameChange || hasPhotoChange) {
        await ApiService.updateProfile(
          fullName: _fullNameController.text.trim(),
          profilePhoto: _selectedImageDataUri,
        );
        // Re-fetch canonical profile so UI always reflects backend-stored photo URL.
        updatedProfile = await ApiService.getProfile();
      }

      if (hasPasswordInput) {
        await ApiService.changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
          confirmPassword: _confirmPasswordController.text,
        );
      }

      if (!mounted) return;
      setState(() {
        _profile = updatedProfile;
        _selectedImageDataUri = null;
        _selectedImageFile = null;
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _isSaving = false;
      });

      _showThemedToast(
        hasPasswordInput
            ? 'Profile and password updated successfully'
            : hasNameChange
                ? 'Profile updated successfully'
                : hasPhotoChange
                    ? 'Profile photo updated successfully'
                    : 'No changes to save',
        isError: false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showThemedToast(
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF1F2937),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFF2C94C), width: 1.2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Text(
      (_profile?.fullName.isNotEmpty ?? false)
          ? _profile!.fullName.trim().substring(0, 1).toUpperCase()
          : 'U',
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 32,
      ),
    );
  }

  Widget _buildProfilePhoto(String value) {
    if (value.startsWith('data:image')) {
      final commaIndex = value.indexOf(',');
      if (commaIndex > 0 && commaIndex < value.length - 1) {
        try {
          final bytes = base64Decode(value.substring(commaIndex + 1));
          return Image.memory(
            bytes,
            width: 114,
            height: 114,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(),
          );
        } catch (_) {
          return _buildAvatarFallback();
        }
      }
      return _buildAvatarFallback();
    }

    String normalized = value.trim();
    if (normalized.startsWith('//')) {
      normalized = 'https:$normalized';
    } else if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'https://$normalized';
    }
    final encodedUrl = Uri.encodeFull(normalized);

    return Image.network(
      encodedUrl,
      width: 114,
      height: 114,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(),
    );
  }

  Widget _buildAvatar() {
    if (_selectedImageFile != null) {
      return Stack(
        children: [
          Container(
            width: 114,
            height: 114,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF2C94C), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF111827),
              backgroundImage: FileImage(File(_selectedImageFile!.path)),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: InkWell(
              onTap: _openPhotoPickerOptions,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFF2C94C),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.black),
              ),
            ),
          ),
        ],
      );
    }

    final profileUrl = _profile?.profilePhoto?.trim() ?? '';
    final hasProfileUrl = profileUrl.isNotEmpty;

    return Stack(
      children: [
        Container(
          width: 114,
          height: 114,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF2C94C), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: const Color(0xFF111827),
            child: hasProfileUrl
                ? ClipOval(
                    child: _buildProfilePhoto(profileUrl),
                  )
                : _buildAvatarFallback(),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: InkWell(
            onTap: _openPhotoPickerOptions,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFF2C94C),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  _buildAvatar(),
                  const SizedBox(height: 14),
                  const Text(
                    'Tap camera icon to add or edit photo',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _fullNameController,
                    cursorColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      label: 'Full Name',
                      icon: Icons.person_outline,
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Please enter your full name';
                      if (text.length < 2) return 'Name must be at least 2 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    initialValue: _profile?.email ?? '',
                    enabled: false,
                    cursorColor: Colors.white,
                    style: const TextStyle(color: Colors.white54),
                    decoration: _inputDecoration(
                      label: 'Email',
                      icon: Icons.email_outlined,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update Password',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrentPassword,
                    cursorColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      label: 'Current Password',
                      icon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureCurrentPassword = !_obscureCurrentPassword;
                          });
                        },
                        icon: Icon(
                          _obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final hasAnyPasswordInput = _currentPasswordController.text.isNotEmpty ||
                          _newPasswordController.text.isNotEmpty ||
                          _confirmPasswordController.text.isNotEmpty;
                      if (!hasAnyPasswordInput) return null;
                      if ((value ?? '').isEmpty) return 'Enter current password';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNewPassword,
                    cursorColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      label: 'New Password',
                      icon: Icons.lock_reset_outlined,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                        icon: Icon(
                          _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final hasAnyPasswordInput = _currentPasswordController.text.isNotEmpty ||
                          _newPasswordController.text.isNotEmpty ||
                          _confirmPasswordController.text.isNotEmpty;
                      if (!hasAnyPasswordInput) return null;
                      final text = value ?? '';
                      if (text.isEmpty) return 'Enter new password';
                      if (text.length < 8) return 'New password must be at least 8 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    cursorColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      label: 'Confirm New Password',
                      icon: Icons.verified_user_outlined,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final hasAnyPasswordInput = _currentPasswordController.text.isNotEmpty ||
                          _newPasswordController.text.isNotEmpty ||
                          _confirmPasswordController.text.isNotEmpty;
                      if (!hasAnyPasswordInput) return null;
                      if ((value ?? '').isEmpty) return 'Confirm new password';
                      if (value != _newPasswordController.text) {
                        return 'Password confirmation mismatch';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('My Profile'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F172A), Color(0xFF111827), Color(0xFF172033)],
              ),
            ),
            child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFF2C94C),
                  ),
                )
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.white, size: 60),
                            const SizedBox(height: 12),
                            const Text(
                              'Failed to load profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF2C94C),
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildProfileForm(),
        ),
      ),
      ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          14 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          border: Border(top: BorderSide(color: Colors.white12)),
        ),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: (_isLoading || _isSaving || _errorMessage != null) ? null : _onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF2C94C),
              disabledBackgroundColor: const Color(0xFFF2C94C).withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save Changes',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
          ),
            ),
        ),
    );
  }
}
