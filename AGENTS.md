# Project guidance

## Project

- `buku555` is a Flutter personal finance app for recording income and expenses.
- Target platforms currently include Android and iOS.
- Use the Dart and Flutter versions allowed by `pubspec.yaml` (`sdk: ^3.12.2`).
- Keep UI code in `lib/screens/` and reusable widgets in `lib/widgets/`.

## Data and money

- SQLite persistence is implemented with `sqflite` in `lib/data/transaction_database.dart`.
- Keep database reads and writes in the database layer; don't add a second persistence path for transactions.
- Transaction amounts are integer cents (`amountInCents`). Keep calculations in integer cents to avoid floating-point rounding errors.
- Use `formatRM` from `lib/utils/money_formatter.dart` for Malaysian Ringgit display.
- Keep transaction mapping consistent with `lib/models/transaction.dart` and the existing SQLite schema. Schema changes need a database version increment and migration handling.

## Flutter and Dart conventions

- Follow the existing Material 3 styling and the lint rules in `analysis_options.yaml`.
- Prefer the existing model and widget patterns; avoid adding dependencies unless they solve a concrete need.
- Keep screens and widgets focused, and use `const` constructors where practical.
- Preserve existing user changes when editing files.

## Useful commands

- `flutter pub get` — resolve dependencies.
- `dart format lib` — format Dart source.
- `flutter analyze` — run static analysis.
- `flutter test` — run the test suite.
