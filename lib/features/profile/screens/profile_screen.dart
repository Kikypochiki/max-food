import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:max_food/features/auth/data/auth_repository.dart';
import 'package:max_food/features/auth/presentation/providers/auth_providers.dart';
import '../models/profile_model.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _addressController = TextEditingController();
  final _imagePicker = ImagePicker();
  bool _isEditing = false;
  Uint8List? _selectedAvatarBytes;
  bool _isUploadingAvatar = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    await ref.read(profileProvider.notifier).updateProfile(
          deliveryAddress: _addressController.text.trim(),
        );

    if (!mounted) return;

    setState(() {
      _isEditing = false;
      _selectedAvatarBytes = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );
  }

  void _startEditing(ProfileModel profile) {
    _addressController.text = profile.deliveryAddress ?? '';
    setState(() {
      _isEditing = true;
    });
  }

  Future<void> _pickAvatar() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      imageQuality: 82,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (!mounted) return;

    setState(() {
      _selectedAvatarBytes = bytes;
      _isUploadingAvatar = true;
    });

    try {
      await ref.read(profileProvider.notifier).uploadAvatar(image);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload photo')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final user = ref.watch(authRepositoryProvider).currentUser;
    final fullName = user?.userMetadata?['full_name'] as String?;
    final displayName = fullName?.trim().isNotEmpty == true
        ? fullName!.trim()
        : user?.email?.split('@').first ?? 'UbayHarvest user';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F8F3),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFF2A8F3A),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: const Color(0xFF2A8F3A),
        actions: [
          IconButton(
            tooltip: 'Refresh profile',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(profileProvider.notifier).fetchProfile(),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
          }

          return RefreshIndicator(
            color: const Color(0xFF2A8F3A),
            onRefresh: () => ref.read(profileProvider.notifier).fetchProfile(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                _ProfileHeader(
                  profile: profile,
                  displayName: displayName,
                  email: user?.email ?? 'No email available',
                  onEdit: () => _startEditing(profile),
                ),
                const SizedBox(height: 16),
                if (_isEditing)
                  _EditProfileForm(
                    avatarUrl: profile.avatarUrl,
                    localAvatarBytes: _selectedAvatarBytes,
                    isUploadingAvatar: _isUploadingAvatar,
                    addressController: _addressController,
                    onChooseAvatar: _pickAvatar,
                    onCancel: () => setState(() {
                      _isEditing = false;
                      _selectedAvatarBytes = null;
                    }),
                    onSave: _saveProfile,
                  )
                else ...[
                  _InfoCard(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    value: user?.email ?? 'No email available',
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.location_on_outlined,
                    title: 'Delivery address',
                    value: profile.deliveryAddress?.trim().isNotEmpty == true
                        ? profile.deliveryAddress!.trim()
                        : 'No address set yet',
                    actionLabel: 'Edit',
                    onAction: () => _startEditing(profile),
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.notifications_none_outlined,
                    title: 'Listing alert preferences',
                    value: 'Manage alert preferences for product categories & farmers',
                    actionLabel: 'Manage',
                    onAction: () => context.push('/alerts/manage'),
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.verified_user_outlined,
                    title: 'Account status',
                    value: 'Ready to buy and manage harvest listings',
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => context.push('/listings/create'),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Create listing'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2A8F3A),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).signOut();
                    },
                    icon: const Icon(Icons.logout_outlined),
                    label: const Text('Sign out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB3261E),
                      side: const BorderSide(color: Color(0xFFE8B4AE)),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2A8F3A)),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load profile.\n$err',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.displayName,
    required this.email,
    required this.onEdit,
  });

  final ProfileModel profile;
  final String displayName;
  final String email;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2A8F3A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: Colors.white,
            backgroundImage: profile.avatarUrl?.trim().isNotEmpty == true
                ? NetworkImage(profile.avatarUrl!.trim())
                : null,
            child: profile.avatarUrl?.trim().isNotEmpty == true
                ? null
                : const Icon(
                    Icons.person,
                    size: 42,
                    color: Color(0xFF2A8F3A),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE4F5E7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Edit profile',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2A8F3A),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileForm extends StatelessWidget {
  const _EditProfileForm({
    required this.avatarUrl,
    required this.localAvatarBytes,
    required this.isUploadingAvatar,
    required this.addressController,
    required this.onChooseAvatar,
    required this.onCancel,
    required this.onSave,
  });

  final String? avatarUrl;
  final Uint8List? localAvatarBytes;
  final bool isUploadingAvatar;
  final TextEditingController addressController;
  final Future<void> Function() onChooseAvatar;
  final VoidCallback onCancel;
  final Future<void> Function() onSave;

  ImageProvider? get _avatarImage {
    if (localAvatarBytes != null) return MemoryImage(localAvatarBytes!);
    if (avatarUrl?.trim().isNotEmpty == true) return NetworkImage(avatarUrl!.trim());
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _avatarImage != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD8E8DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit profile',
            style: TextStyle(
              color: Color(0xFF1D4F2A),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFFE7F4E9),
                    backgroundImage: _avatarImage,
                    child: hasImage
                        ? null
                        : const Icon(
                            Icons.person,
                            color: Color(0xFF2A8F3A),
                            size: 34,
                          ),
                  ),
                  if (isUploadingAvatar)
                    const Positioned.fill(
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: Color(0x66000000),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isUploadingAvatar ? null : onChooseAvatar,
                  icon: isUploadingAvatar
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF2A8F3A),
                          ),
                        )
                      : const Icon(Icons.photo_library_outlined),
                  label: Text(isUploadingAvatar ? 'Uploading...' : 'Choose photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2A8F3A),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: addressController,
            minLines: 3,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: 'Delivery address',
              alignLabelWithHint: true,
              prefixIcon: const Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FBF8),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.check),
                  label: const Text('Save'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2A8F3A),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD8E8DA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F4E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF2A8F3A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF667A6C),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF1D4F2A),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
