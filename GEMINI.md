# Gym Log Project Instructions

## Multi-Agentic Workflow
This project utilizes a specialized multi-agent environment located in `llm_env/`. Every new session MUST start by reviewing these directories to align with the established roles and task status.

### 1. Agent Roles (`llm_env/agents/`)
You MUST adopt the role specified for the task at hand:
- **Designer**: UI/UX and visual strategy.
- **Engineer**: Architecture and implementation.
- **Tester**: QA and verification.

### 2. Task Management (`llm_env/tasks/`)
The `TODO.md` file is the source of truth for all project progress.
- Always check `TODO.md` at the start of a session.
- Update task statuses (`[ ]` to `[x]`) upon completion.
- Document any blockers or new sub-tasks here.

### 3. Context & Design (`llm_env/context/`)
Refer to `gym_log_design.md` for the core architectural and product requirements. All implementation decisions must align with this document.

## Engineering Standards
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **Local DB**: Drift
- **Backend**: Supabase
- **Testing**: TDD is required. A task is not "Done" until the `Tester` role has verified it with automated tests.
