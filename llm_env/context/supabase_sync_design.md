# Supabase Synchronization - Technical Specification

## Overview
Mettle uses an offline-first approach. All data is first written to the local Drift database. A background worker periodically synchronizes local changes with the Supabase backend.

## Synchronization Strategy (Outbound)
1.  **Change Tracking**:
    - Add a `synced` boolean column to all syncable tables (`Routines`, `Schedules`, `WorkoutSessions`, `SetLogs`).
    - Add a `lastModified` timestamp to handle conflicts.
2.  **Sync Trigger**:
    - `Workmanager` will run a task every 15 minutes (minimum allowed by Android).
    - Manual sync trigger when the app comes to the foreground or after a workout is finished.
3.  **Conflict Resolution**:
    - Last-Write-Wins (LWW) based on `lastModified`.
    - Supabase will be the source of truth for IDs (UUIDs). Local IDs will be mapped to remote UUIDs.

## Database Changes
Update `lib/core/database/database.dart`:
- Add `TextColumn get remoteId => text().nullable()();` (UUID from Supabase).
- Add `BoolColumn get isSynced => boolean().withDefault(const Constant(false))();`
- Add `DateTimeColumn get lastModified => dateTime().withDefault(currentDateAndTime)();`

## Supabase Client Setup
- Initialize Supabase in `main.dart`.
- Create a `SyncRepository` to handle the heavy lifting of diffing local vs remote.

## Background Worker
- `lib/core/sync/sync_worker.dart` will contain the top-level callback for `Workmanager`.
- It will initialize its own `ProviderContainer` to access the database and Supabase client.
