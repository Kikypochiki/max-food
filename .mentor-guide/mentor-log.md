# Mentor Log - UbayHarvest

## Historical Decisions & Changes
- **2026-04-18:** Initialized Flutter project `max_food` using Riverpod, GoRouter, and Supabase.
- **2026-04-18:** Completed `feature/landing-page` with basic UI and routing base.
- **2026-04-18:** Completed `feature/auth` implementing strict Deep-Linked Email Confirmation using `supabase_flutter` Native App Links and GoRouter redirects. Decided to bypass traditional `authCallbackUrlHostname` configuration due to `app_links` implicit handling in v2 of the SDK. Opted out of Google Auth for phase 1.
