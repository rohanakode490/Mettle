# Active Workout Tracker - UI/UX Specification

## Overview
The Active Workout screen is where the user logs their actual performance. It must be highly responsive and provide context from previous sessions.

## User Journeys
1. **Start Workout**:
    - From Home, user taps "Start Workout".
    - A new `WorkoutSession` is created in Drift.
    - If started from a routine, the exercises from that routine are pre-loaded.
2. **Logging a Set**:
    - For each exercise, the user sees a list of sets.
    - Each set has inputs for Weight and Reps.
    - **CRITICAL**: Next to the inputs, the screen shows the metrics from the *previous* session for that same exercise and set index.
3. **Add/Remove Exercise**:
    - User can add an ad-hoc exercise during the session.
    - User can skip or remove an exercise.
4. **Finish Workout**:
    - User taps "Finish".
    - `endTime` is recorded.
    - User can add a summary note.

## UI Components
- **WorkoutHeader**: Shows elapsed time and routine name.
- **ExerciseCard**:
    - List of `SetRow` widgets.
    - "Add Set" button.
- **SetRow**:
    - Label (Set 1, 2, etc.).
    - Previous data display (e.g., "Prev: 60kg x 8").
    - Input fields (Weight, Reps).
    - Status checkbox (done).
- **SessionSummaryDialog**: Appears on finish, allows notes.

## Styling Guidelines
- **Focus**: Large touch targets for input fields (gym-friendly).
- **Contextual Data**: Use a subtle gray or italics for the "Previous" data to distinguish it from current inputs.
- **Visual Progress**: Check off sets as they are completed.

## Data Integration
- `WorkoutRepository` to manage `WorkoutSessions` and `SetLogs`.
- `ActiveWorkoutNotifier` (Riverpod) to hold the state of the current session.
- SQL query to fetch the most recent `SetLog` for a given `exerciseId` and `orderIndex`.
