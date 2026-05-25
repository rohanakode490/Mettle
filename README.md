# Mettle

Mettle is a powerful, offline-first gym progress tracker built with Flutter. It focuses on providing real-time historical context during your workouts to help you push your limits.

## Features

- **Today's Focus**: Instantly see what's scheduled for today and jump into action.
- **Contextual Logging**: See your previous session's weight and reps inline for every set. No more guessing.
- **Routine Builder**: Easily create and reorder workout templates with a gym-friendly interface.
- **Weekly Scheduler**: Map your routines to days of the week for a structured training plan.
- **Offline-First**: Powered by a local SQLite database (Drift) for blazing-fast performance without needing an internet connection.
- **State-of-the-Art Management**: Built with Riverpod for a reactive and robust user experience.

## Getting Started

1.  Ensure you have the Flutter SDK installed.
2.  Clone the repository.
3.  Run `flutter pub get`.
4.  Run `dart run build_runner build` to generate the database and state management code.
5.  Launch the app with `flutter run`.

## Tech Stack

- **Framework**: Flutter
- **State Management**: Riverpod
- **Local Database**: Drift (SQLite)
- **Backend (Planned)**: Supabase for cloud sync and authentication.
- **Charts**: fl_chart for progress visualization.

## Architecture

Mettle follows a modular feature-based architecture:
- `core/`: Shared database, providers, and utilities.
- `features/routine/`: Logic and UI for managing workout templates.
- `features/schedule/`: Daily overview and weekly planning.
- `features/workout/`: The active logging experience.

---
*Mettle: The resilience to persevere and the spirit to overcome.*
