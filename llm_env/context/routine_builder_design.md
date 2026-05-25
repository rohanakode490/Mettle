# Routine Builder - UI/UX Specification

## Overview
The Routine Builder allows users to create and manage workout templates (Routines). A routine consists of a name and a list of exercises in a specific order.

## User Journeys
1. **View Routines**: Home screen or a dedicated "Routines" tab shows all saved routines.
2. **Create Routine**:
    - User clicks "+" button.
    - User enters a name for the routine (e.g., "Leg Day").
    - User adds exercises from a searchable list.
    - User can reorder exercises using drag-and-drop.
    - User saves the routine.
3. **Assign to Schedule**:
    - On the routine detail or edit screen, the user can toggle days of the week (M, T, W, T, F, S, S).

## UI Components
- **RoutineListScreen**:
    - `ListView` of routine cards.
    - Each card shows the name and a summary of exercises.
- **RoutineEditorScreen**:
    - `TextField` for the routine name.
    - `ReorderableListView` for the exercises.
    - `IconButton` (Add) to open the exercise selector.
    - `MultiSelectChipGroup` for days of the week.
- **ExerciseSelector**:
    - A modal or full-screen dialog with a search bar and a list of exercises.

## Styling Guidelines
- **Primary Color**: Blue (from `ThemeData`).
- **Typography**: Clean, sans-serif (Default Flutter typography).
- **Interactive Feedback**: Haptic feedback on reorder, clear visual cues for adding/removing.

## Data Integration
- `RoutineRepository` will handle Drift DB operations for CRUD.
- `RoutineProvider` (Riverpod) will manage the state of the current routine being edited.
