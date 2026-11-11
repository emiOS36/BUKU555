# Buku555 Project Guidance

## Project

Buku555 is a Flutter app for recording income and expenses, with statistics and transaction history.

- Platform: Android and iOS
- Dart SDK: `^3.12.2` (see `pubspec.yaml`)
- UI: Material 3
- Persistence: SQLite through `sqflite`

Treat the current repository as the source of truth. Before giving implementation advice or changing code, inspect the relevant current files and dependencies. Do not rely on old conversation snippets when they conflict with the source. Inspect only what the task needs; do not repeatedly scan the whole project for a small change.

Preserve existing user changes. Keep changes focused on the request, and do not commit or push unless asked.

## Code Changes

- Do not edit or create project code unless the user explicitly requests a code change.
- For questions, reviews, or advice, inspect files as needed and explain findings without modifying them.
- When a code change is requested, keep it within the requested scope and preserve unrelated user changes.

## Project Structure

Follow the existing organization:

- `lib/screens/` — screens
- `lib/widgets/` — reusable UI components
- `lib/data/` — persistence and database operations
- `lib/models/` — data models
- `lib/utils/` — shared helpers

Do not add a new state-management or architecture layer unless the current code has a concrete problem that justifies it. Keep solutions straightforward and avoid unrelated refactoring.

## Flutter and Dart

- Follow Flutter, Dart, and the project lint rules.
- Prefer strong types, null safety, meaningful names, and `const` constructors where practical.
- Use `StatelessWidget` or `StatefulWidget` according to the state the widget owns.
- Keep functions focused and handle asynchronous work and resource disposal correctly.
- Extract widgets or helpers when that improves reuse or readability; do not split code into files without a reason.
- Do not suppress analyzer warnings without understanding and fixing their cause where possible.

## Transactions, Money, and Dates

Financial accuracy is essential.

- Store transaction amounts as integer cents in `amountInCents`; do not use `double` as the authoritative money value.
- Keep calculations in integer cents. When a calculation needs rounding, define the rounding behavior explicitly.
- Use `formatRM` from `lib/utils/money_formatter.dart` to display Malaysian Ringgit. Formatting must never change the stored amount.
- Keep transaction types, categories, and model mapping consistent with `lib/models/transaction.dart` and the existing database schema.
- Prevent invalid values, missing IDs, and accidental double-counting when adding, editing, deleting, or summarizing transactions.
- Use consistent calendar boundaries for reports: include the start date and exclude the end date (`[start, end)`). Be clear whether a period means a calendar month/year, a rolling range, or a completed period.
- Keep important financial calculations small enough to reason about and test independently.

## SQLite

`lib/data/transaction_database.dart` is the single persistence path for transactions.

- Keep SQL and persistence logic in the database layer. Screens and other UI code may call its methods; they should not contain SQL or create another persistence path.
- Use parameterized queries and handle database errors and missing records appropriately.
- Avoid unnecessary database reads and preserve existing records.
- For a schema change, increment the database version and add a migration that preserves existing user data. Do not reset or recreate the database as a shortcut.
- Consider both new database creation and upgrade behavior when a migration is part of the requested work.

## UI and UX

- Follow the existing Material 3 theme and keep screens visually consistent across Android and iOS.
- Reuse existing colors, typography, spacing, and widgets where appropriate.
- Keep financial values readable; handle long descriptions and large amounts without overflow.
- Provide appropriate loading, empty, success, and error states.
- Do not communicate essential meaning by color alone; respect safe areas and keyboard visibility.
- Avoid redesigning existing screens unless requested or needed to resolve a demonstrated usability problem.

## Errors and Performance

- Do not silently ignore errors or show raw internal exceptions to users.
- Show clear user-facing messages while retaining useful, non-sensitive debugging details.
- Do not report success until the operation succeeds.
- Keep the UI responsive. Use lazy lists for long histories and avoid unnecessary queries or repeated expensive work in `build` methods.
- Optimize only when there is a demonstrated need.

## Dependencies

Before adding a package, check whether Flutter, Dart, or an existing dependency already provides the needed feature. Add a dependency only when it solves a concrete problem; consider maintenance, compatibility, security, and performance. Keep `pubspec.yaml` and `pubspec.lock` consistent. Do not upgrade Flutter or packages without a reason.

## Planning, Tests, and Verification

For a small, focused change, inspect the relevant code and proceed directly. For a change spanning multiple files or affecting data, explain the planned files, behavior, and important risks before implementation.

When tests or verification are part of the request:

- Prefer focused tests for money calculations, date ranges, transaction validation, model mapping, and database behavior.
- Add or update widget tests when important user-visible behavior is in scope.
- For database migrations, verify both fresh creation and upgrades while preserving existing data.
- Format modified Dart files and run the relevant analyzer or tests requested for the task.
- Report exactly which checks were run and their results. Do not claim a check passed if it was not run.

Keep testing proportional to the change. A visual-only adjustment does not need database tests; a date calculation or money change deserves focused coverage.

## Communication and Learning

The project owner is learning Flutter. Explain unfamiliar or important implementation choices in plain language, using the current Buku555 code as context. Avoid explaining basic syntax unless asked. If a request could cause financial inaccuracies, data loss, or unnecessary complexity, explain the issue and recommend a safer approach before making a significant out-of-scope change.

## Completion

Before reporting a code change as complete, review the diff, confirm that the requested behavior is covered, and state any checks performed or limitations. Preserve unrelated working-tree changes and be honest about anything not verified.
