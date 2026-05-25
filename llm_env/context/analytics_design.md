# Analytics & Charts - UI/UX Specification

## Overview
The Analytics screen provides visual feedback on the user's progress over time. It helps users stay motivated by seeing their strength and volume increases.

## User Journeys
1. **View Progress per Exercise**:
    - User selects an exercise (e.g., "Bench Press").
    - A line chart shows the Maximum Weight lifted over the last 30 days.
2. **Weekly Volume Trend**:
    - A bar chart shows the total weight lifted (Weight x Reps) per week.
3. **Session Consistency**:
    - A calendar-style view or simple count of workouts per week.

## UI Components
- **ExercisePicker**: A dropdown or search field to filter charts.
- **ProgressLineChart**:
    - X-axis: Date.
    - Y-axis: Max Weight (kg).
    - Tooltips on tap showing exact date and weight.
- **VolumeBarChart**:
    - X-axis: Week Number or Start Date.
    - Y-axis: Total Volume (tons or kg).

## Styling Guidelines
- **Color Palette**: Use different shades of blue and complementary accent colors for different metrics.
- **Responsiveness**: Charts should scale correctly on different screen sizes.

## Data Integration
- `AnalyticsRepository`: Complex Drift queries to aggregate data.
- `exerciseProgressProvider`: Fetches historical data for a specific exercise.
- `weeklyVolumeProvider`: Aggregates volume across all sessions.
