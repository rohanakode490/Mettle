# Home/Schedule - UI/UX Specification

## Overview
The Home screen provides a summary of the current week's schedule and highlights today's workout. It is the primary jumping-off point for starting a session.

## User Journeys
1. **View Today's Workout**:
    - The screen prominently displays the name of the routine scheduled for "Today".
    - If no routine is scheduled, it suggests picking one or resting.
    - A large "Start Workout" button appears if a routine is scheduled.
2. **Weekly Schedule**:
    - A horizontal or vertical list of the 7 days of the week.
    - Each day shows the routine assigned to it.
    - User can tap a day to change or assign a routine.
3. **Quick Start**:
    - A secondary button to "Start Empty Workout" (without a routine).

## UI Components
- **TodayCard**:
    - Displays Routine Name, number of exercises.
    - "Start Workout" primary button.
- **WeeklyCalendarView**:
    - A row of 7 items.
    - Today is highlighted.
- **RecentWorkoutsSummary**:
    - A brief list of the last 3 completed sessions.

## Styling Guidelines
- **Call to Action**: Use the primary blue for "Start Workout".
- **Empty States**: Encouraging text and a clear path to the Routine Builder.

## Data Integration
- `ScheduleRepository` to manage Drift `Schedules` table.
- `WorkoutRepository` to fetch today's routine and recent sessions.
- `todayRoutineProvider` to reactively show what's scheduled.
