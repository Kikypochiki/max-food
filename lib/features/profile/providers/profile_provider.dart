import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:max_food/core/providers/supabase_providers.dart';
import 'package:max_food/features/auth/presentation/providers/auth_providers.dart';
import '../models/profile_model.dart';

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<ProfileModel?>>((ref) {
  ref.watch(authStateProvider);
  return ProfileNotifier(ref.watch(supabaseClientProvider));
});

class ProfileNotifier extends StateNotifier<AsyncValue<ProfileModel?>> {
  final SupabaseClient _supabase;

  ProfileNotifier(this._supabase) : super(const AsyncValue.loading()) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        final emptyProfile = ProfileModel(id: user.id);
        state = AsyncValue.data(emptyProfile);
      } else {
        state = AsyncValue.data(ProfileModel.fromJson(response));
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateProfile({
    String? avatarUrl,
    String? deliveryAddress,
    bool showLoading = true,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      if (showLoading) state = const AsyncValue.loading();

      final updates = {
        'id': user.id,
        'avatar_url': ?avatarUrl,
        'delivery_address': ?deliveryAddress,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('profiles')
          .upsert(updates)
          .select()
          .single();

      state = AsyncValue.data(ProfileModel.fromJson(response));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> uploadAvatar(XFile image) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final bytes = await image.readAsBytes();
      final extension = image.name.split('.').last.toLowerCase();
      final safeExtension = extension.isEmpty || extension.length > 5
          ? 'jpg'
          : extension;
      final path =
          '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$safeExtension';

      await _supabase.storage.from('profile_avatars').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: image.mimeType ?? 'image/jpeg',
            ),
          );

      final avatarUrl =
          _supabase.storage.from('profile_avatars').getPublicUrl(path);

      await updateProfile(avatarUrl: avatarUrl, showLoading: false);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
