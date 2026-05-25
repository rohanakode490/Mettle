---
name: minimalist-flutter-ux
description: Use when building or refactoring Flutter UI to be minimalist and beginner-focused. Focuses on reducing visual noise, enhancing whitespace, and prioritizing single primary actions.
---

# Minimalist Flutter UX

## Overview
This skill guides the creation of clean, non-intimidating, and highly functional mobile interfaces for Flutter. It prioritizes the "beginner's mind" by removing unnecessary decorations and focusing on clear intent.

## Core Principles

### 1. The "One Big Action" Rule
Every screen must have a singular, clear path for the user. 
- Avoid multiple secondary buttons.
- Use prominent full-width primary buttons (minimum 56dp height).
- Use `floatingActionButton` only for the absolute core action (e.g., "Start Workout").

### 2. Whitespace as a Component
Whitespace is not "empty space"; it is a tool for focus.
- **Screen Padding**: Minimum 24dp for horizontal padding.
- **Inter-Section Spacing**: Minimum 32dp between logical sections.
- **Component Spacing**: Use `SizedBox(height: 16)` as the default gap.

### 3. Soft UI Elements
Avoid high-contrast borders and heavy shadows.
- **Elevation**: Set to `0` or `1`. Prefer `Border.all(color: Colors.grey[200])`.
- **Colors**: Use a single primary color for actions. Use `Theme.of(context).colorScheme.surface` for backgrounds.
- **Cards**: Use 16dp-24dp corner radii.

### 4. Human-Centric Text
Replace technical jargon with conversational, motivating text.
- ❌ "Routine List" -> ✅ "Your Programs"
- ❌ "Add Exercise" -> ✅ "Choose a Movement"
- ❌ "Save" -> ✅ "All Set!"

## Implementation Guidelines

### Progressive Disclosure
Don't overwhelm beginners. 
- Use `showModalBottomSheet` for secondary filters or settings.
- Avoid persistent filter bars if they clutter the view.

### Empty States
An empty list is an opportunity for encouragement.
- Use a single illustrative icon (e.g., `Icons.auto_awesome`).
- Provide a clear, inviting call to action.

## Quick Reference

| Element | Minimalist Standard |
|---------|---------------------|
| Padding | 24dp (horizontal) |
| Radius | 16dp - 24dp |
| Elevation | 0 |
| Button Height | 56dp |
| Title Font | FontWeight.bold, size 24+ |

**REQUIRED BACKGROUND:** For specific code snippets, read [references/ui_patterns.md](references/ui_patterns.md).
