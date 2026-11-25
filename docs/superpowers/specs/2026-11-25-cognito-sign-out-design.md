# Cognito Sign-out and Startup Session Design

## Intent

Keep Buku555's login screen in sync with the user's Cognito session. If Cognito has a valid signed-in session, startup opens the app directly. A Settings action lets the user end that session and return to Login.

## Approaches

- **Sign-out button only:** smaller change, but startup can still show Login while Cognito has an active session. Rejected because it leaves the current “already signed in” problem in place.
- **Session-aware startup plus sign-out (chosen):** check the current Cognito session at startup, route to the matching screen, and let the user sign out from Settings. This handles both the active-session problem and the requested action.

## Design

- Add a startup auth gate that checks `Amplify.Auth.fetchAuthSession()` and displays a brief loading state while checking. An active session opens `NavigationScreen`; otherwise show `LoginScreen`.
- Add a full-width outlined red Sign out button after the About section in Settings.
- Ask for confirmation before signing out. On success, clear the navigation stack and show `LoginScreen`. If sign-out fails, remain in Settings and show a clear error message.
- Do not delete or alter local SQLite transactions when signing out.

## Scope and constraints

- Likely files: `lib/main.dart`, `lib/screens/settings_screen.dart`, and a small auth-gate widget under `lib/screens/` if that keeps startup code clear.
- No changes to Cognito pool settings, sign-up/verification flows, cloud sync, or local transaction storage.
- Verification: format and analyze the changed Dart files; manually confirm signed-out startup, signed-in startup, sign-out, and preservation of local transactions.
