# Gym Log Initial Design (2026-05-24)

## Architecture Overview
- **Framework**: Flutter
- **State Management**: Riverpod
- **Local Database**: Drift (SQLite)
- **Cloud Backend**: Supabase (Postgres)
- **Sync Strategy**: Speed-first background synchronization using a `SyncQueue`.

## Core UI: Active Workout Screen
- **Historical Context**: Inline Ghosting (previous weight/reps shown as greyed-out placeholders).
- **Set Management**: 
  - Exercise headers with notes.
  - Set rows with thumb-friendly inputs.
  - Completion toggle triggers a rest timer.
- **Rest Timer**: Bottom banner with "Skip" and "+30s" options.

## Agent Roles
- **Designer**: UI/UX, animations, and visual consistency.
- **Engineer**: Architecture, Drift/Supabase implementation, and core logic.
- **Tester**: Unit tests for sync/logic and widget tests for the Active Workout UI.

## Testing Strategy
- **Unit**: Validate `SyncQueue` retry logic and Routine scheduling algorithms.
- **Widget**: Verify "Inline Ghosting" displays correct previous values.
- **Integration**: Full flow from "Start Workout" to "Finish & Sync".
