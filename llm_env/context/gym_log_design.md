# Gym Log Application Design Document

## Background & Motivation
The user wants to build a mobile application to log gym progress. The app must schedule routines to specific days (e.g., Monday's workout), track workouts with charts, and critically, show the previous weight and reps for each set during an active session.

## Scope & Impact
- A mobile application built with Flutter.
- Offline-first approach with local database and cloud sync capabilities.
- Core features include routine scheduling, active workout tracking, progress charts, and historical set context.

## Proposed Solution (Architecture & Core Models)
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **Local Database**: Drift (SQLite) for highly relational, fast offline data.
- **Cloud Backend**: Supabase for Postgres synchronization and Auth.
- **Core Entities**:
  - `Routine`: A template (e.g., "Monday Heavy Legs").
  - `RoutineExercise`: The exercises planned for a routine.
  - `Schedule`: Maps routines to specific days of the week.
  - `WorkoutSession`: An active or completed workout.
  - `SetLog`: The actual reps and weight performed.

## Implementation Plan (UI & Data Flow)
1. **Home/Schedule**: Displays today's scheduled routine with a quick "Start Workout" button.
2. **Active Workout**: The main screen. Shows current exercises and sets. It will query the Drift DB to show the *previous session's* metrics inline for each set.
3. **Routine Builder**: Create custom routines and assign them to days.
4. **Analytics/Charts**: Track progress (e.g., estimated 1RM, volume) using `fl_chart`.

**Data Flow**: Set logged -> Written to local Drift DB -> UI updates instantly -> Background worker syncs to Supabase if online.

## Verification & Error Handling
- **Silent Retries**: Failed cloud syncs are flagged locally (`needs_sync`) and retried in the background.
- **Input Validation**: Safeguards against typos (e.g., absurd weights) to keep analytics clean.
- **Testing**:
  - Unit tests for routine scheduling algorithms and sync queue.
  - Widget tests for the Active Workout UI responsiveness.
  - Integration tests for a full workout lifecycle.