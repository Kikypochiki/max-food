# Mentor Log - UbayHarvest

## Historical Decisions & Changes
- **2026-04-18:** Initialized Flutter project `max_food` using Riverpod, GoRouter, and Supabase.
- **2026-04-18:** Completed `feature/landing-page` with basic UI and routing base.
- **2026-04-18:** Completed `feature/auth` implementing strict Deep-Linked Email Confirmation using `supabase_flutter` Native App Links and GoRouter redirects. Decided to bypass traditional `authCallbackUrlHostname` configuration due to `app_links` implicit handling in v2 of the SDK. Opted out of Google Auth for phase 1.
- **2026-06-03:** Completed `feature/profile-configuration` implementing profile view/updates, delivery address management, image picker avatar upload to Supabase Storage, and state sync with Riverpod. Resolved Dart 3.7+ null-aware collection element lints (`use_null_aware_elements`).
- **2026-06-04:** Fixed Android build failure caused by AGP 8.11.1 + CMake 3.22.1 file-locking on `generate_cxx_metadata` timing logs. Root cause: Flutter SDK's dummy `CMakeLists.txt` triggers full CMake configure pipeline; Windows Defender locks timing files mid-write. Fix: forced CMake 4.0.2 via `externalNativeBuild` block in `build.gradle.kts`.
- **2026-06-04:** Fixed profile state not resetting on account switch. Removed duplicate `supabaseClientProvider` from `profile_provider.dart`, added `ref.watch(authStateProvider)` dependency so `ProfileNotifier` auto-invalidates and refetches on auth state changes (sign-in/sign-out).
- **2026-06-04:** Completed real-time buyer-seller chat system using Supabase Realtime subscriptions. Added database migration for `chat_rooms` and `chat_messages` with Row Level Security (RLS) and enabled Realtime replication. Updated `profiles` table to include `full_name` and added a trigger on `auth.users` to automatically sync user details. Created Listing Detail screen with draft messages, Chat Inbox showing conversation threads, and Chat Room with live bidirectional stream subscriptions via Riverpod.
- **2026-06-04:** Implemented Listing Alerts and message notifications system. Added database migration for `listing_alerts_subscriptions` and `notifications` tables with RLS policies, trigger functions (`handle_new_listing_notification` and `handle_new_chat_message_notification`), and Supabase Realtime subscriptions. Created `AlertRepository` and Riverpod providers to handle subscriptions and notifications. Designed and integrated alert management screen, notification center screen, profile settings tile, and real-time custom sliding toast overlay on the home screen.


