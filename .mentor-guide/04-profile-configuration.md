# 04 - Profile Configuration

## Mission
Implement the user profile configuration feature where users can manage their avatar, delivery address, and sync their profile data with Supabase.

## Success Criteria
- User can view their profile data
- User can update their avatar
- User can update their delivery address
- Changes sync with Supabase in real-time

## Prerequisites
- Authentication is complete and the user has a valid session.

## Step-by-Step Implementation

1. **Create Profile Model (`lib/features/profile/models/profile_model.dart`)**
   Define the data structure for the user's profile.

2. **Create Profile Provider (`lib/features/profile/providers/profile_provider.dart`)**
   Set up Riverpod state management for fetching and updating the profile data from Supabase.

3. **Create Profile Screen (`lib/features/profile/screens/profile_screen.dart`)**
   Build the UI for viewing and editing the profile, including a placeholder or avatar image picker and a form for the address.

4. **Update Router (`lib/core/router/app_router.dart`)**
   Add the profile route.

## Verification Checklist
- [x] Profile model parses Supabase JSON correctly.
- [x] Profile provider correctly updates state.
- [x] Profile screen updates reactively when data changes.

## Commit Flow
- `feat(profile): add profile model`
- `feat(profile): add profile provider for state management`
- `feat(profile): create profile screen UI`
- `feat(router): add profile route`
