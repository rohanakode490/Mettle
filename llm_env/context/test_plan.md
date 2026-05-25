# Mettle - Test Plan

## Overview
This plan outlines the strategy for verifying the core functionality of the Mettle application, focusing on data integrity and user workflows.

## 1. Unit Tests (Repositories & Logic)
- **RoutineRepository**:
    - Verify routine creation with associated exercises.
    - Verify routine deletion cleans up join tables.
- **ScheduleRepository**:
    - Verify setting a schedule for a specific day.
    - Verify fetching today's routine accurately identifies the weekday.
- **WorkoutRepository**:
    - Verify session start/finish timestamps.
    - **CRITICAL**: Verify `getPreviousSet` correctly retrieves the *most recent* set for a specific exercise and index from a *different* session.

## 2. Widget Tests (UI)
- **HomeScreen**:
    - Verify it displays "Rest Day" when no workout is scheduled.
    - Verify "Start Workout" appears when a routine is scheduled.
- **RoutineEditor**:
    - Verify adding an exercise updates the list.
    - Verify reordering exercises changes their position.

## 3. Integration Tests
- **Full Workout Lifecycle**:
    - Create a routine -> Schedule it for today -> Start workout -> Log sets -> Finish -> Verify data in DB.

## Implementation Priorities
1. Unit tests for `WorkoutRepository` (especially `getPreviousSet`).
2. Unit tests for `ScheduleRepository`.
3. Basic UI smoke tests for Home and Routine screens.
