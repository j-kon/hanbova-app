import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _firstNameController = TextEditingController(text: profile.firstName);
    _lastNameController = TextEditingController(text: profile.lastName);
    _usernameController = TextEditingController(text: profile.username);
    _phoneController = TextEditingController(text: profile.phone);
    _emailController = TextEditingController(text: profile.email);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showPhotoOptions(BuildContext context) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.textTertiary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Profile Photo',
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  leading:
                      Icon(Icons.camera_alt_outlined, color: colors.primary),
                  title: const Text('Take Photo'),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    // Mock local photo path
                    await ref
                        .read(profileProvider.notifier)
                        .setAvatar('assets/demo/avatar_camera.png');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile photo updated.')),
                      );
                    }
                  },
                ),
                ListTile(
                  leading:
                      Icon(Icons.photo_library_outlined, color: colors.primary),
                  title: const Text('Choose from Library'),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    // Mock local photo path
                    await ref
                        .read(profileProvider.notifier)
                        .setAvatar('assets/demo/avatar_library.png');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile photo updated.')),
                      );
                    }
                  },
                ),
                ListTile(
                  leading:
                      Icon(Icons.delete_outline_rounded, color: colors.error),
                  title: Text(
                    'Remove Photo',
                    style: TextStyle(color: colors.error),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    await ref.read(profileProvider.notifier).removeAvatar();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile photo removed.')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _saveProfile() async {
    final colors = context.colors;
    await ref.read(profileProvider.notifier).updateProfile(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          username: _usernameController.text,
          phone: _phoneController.text,
          email: _emailController.text,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully.'),
          backgroundColor: colors.primary,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final profile = ref.watch(profileProvider);
    final residence = profile.residenceCountryInfo;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Edit Profile',
          style: AppTypography.titleMedium.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: Text(
              'Save',
              style: AppTypography.titleSmall.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Profile Avatar Editor
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => _showPhotoOptions(context),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: colors.primary.withValues(alpha: 0.15),
                      child: Text(
                        profile.initials,
                        style: AppTypography.headline.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _showPhotoOptions(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: colors.background, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: () => _showPhotoOptions(context),
                child: Text(
                  'Change Profile Photo',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 2. Personal Information (Editable)
            Text(
              'PERSONAL INFORMATION',
              style: AppTypography.labelSmall.copyWith(
                color: colors.textTertiary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _firstNameController,
              label: 'First Name',
              hint: 'Jeremiah',
              colors: colors,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _lastNameController,
              label: 'Last Name',
              hint: 'Jacob',
              colors: colors,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _usernameController,
              label: 'Username',
              hint: 'jaykon',
              prefixText: '@',
              colors: colors,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: '+234 803 123 4567',
              keyboardType: TextInputType.phone,
              colors: colors,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'jeremiah@hanbova.org',
              keyboardType: TextInputType.emailAddress,
              colors: colors,
            ),
            const SizedBox(height: AppSpacing.xl),

            // 3. Identity Information (Protected / Verified)
            Text(
              'IDENTITY & RESIDENCE',
              style: AppTypography.labelSmall.copyWith(
                color: colors.textTertiary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: AppRadius.mdRadius,
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Country of Residence',
                          style: AppTypography.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_user_rounded,
                              size: 11,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Verified Origin',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        residence.flagEmoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        residence.name,
                        style: AppTypography.titleSmall.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(color: colors.divider),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: colors.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Changing your country of residence may require verification.',
                          style: AppTypography.caption.copyWith(
                            color: colors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: AppColors.charcoal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdRadius,
                ),
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? prefixText,
    TextInputType keyboardType = TextInputType.text,
    required dynamic colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: AppTypography.bodyMedium.copyWith(
            color: colors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.textTertiary),
            prefixText: prefixText != null ? '$prefixText ' : null,
            prefixStyle: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
            filled: true,
            fillColor: colors.surfaceCard,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: AppRadius.mdRadius,
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.mdRadius,
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.mdRadius,
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
