# Charflow — Project Brief (iOS-first)

## One-liner
**Charflow** is a clean, minimal daily task manager built around **four day regions**—**Morning**, **Afternoon**, **Evening**, and **Backlog**—where each active region uses a **1–3–5** structure to keep focus and prevent list bloat.

> Char = Persian root for **4** → four regions, one focused flow.

---

## The problem Charflow solves
Most task apps become endless lists. People over-plan, lose focus, and tasks silently rot. Charflow replaces the infinite backlog mindset with a *daily, time-of-day* plan that stays small, intentional, and doable—while still preserving anything unfinished.

---

## Core concept
### Four regions
1. **Morning**
2. **Afternoon**
3. **Evening**
4. **Backlog** (accumulated unfinished work + future ideas)

### The 1–3–5 rule (per region)
For **Morning**, **Afternoon**, and **Evening**:
- **1 Must-Do**: the single critical outcome for that region.
- **3 Complementary**: important support tasks unlocked *after* the Must-Do is complete (or explicitly overridden).
- **5 Misc**: small, low-friction tasks that are nice to clear.

**Backlog** is not constrained by 1–3–5 by default (configurable). It’s a holding area that automatically collects unfinished tasks from previous days unless the user specifies otherwise.

---

## North Star behavior
Charstack should help the user **finish the Must-Do for the current region**, with minimal friction and maximum clarity.

---

## Primary user flow (MVP)
1. **Plan the day** quickly:
   - Add tasks into Morning / Afternoon / Evening.
   - Each region has slots: **1 Must**, **up to 3 Complementary**, **up to 5 Misc**.
2. **Do the work** in a focused region view:
   - The Must-Do is always visually dominant.
   - Complementary tasks are de-emphasized or locked until Must-Do completion (configurable).
3. **Carry-over happens automatically**:
   - Uncompleted tasks move into **Backlog** at day rollover.
   - The user can “reschedule” tasks from Backlog back into specific regions.
4. **Calendar awareness** (read-first):
   - Show the user’s calendar events alongside regions.
   - Suggest appropriate regions/time windows for tasks (later).

---

## Screens (iOS-first, minimal set)
### 1) Today (Region Dashboard)
- Four cards/sections: Morning / Afternoon / Evening / Backlog
- Each region shows:
  - Must-Do (title + status)
  - Count of Complementary + Misc remaining
  - A simple progress indicator

### 2) Region Focus View
- Displays tasks for a single region using the 1–3–5 grouping
- Quick interactions: complete, reorder, move to another region, defer, add note

### 3) Backlog
- A clean list grouped by source (e.g., “Yesterday”, “Last Week”, “Older”)
- Fast “Pull into Today” gestures:
  - Assign to Morning/Afternoon/Evening
  - Optionally place as Must / Complementary / Misc

### 4) Plan / Review
- Evening planning prompt (or morning):
  - Review backlog items
  - Fill each region’s 1–3–5 slots
- End-of-day recap:
  - Mark items as done / defer / archive / drop

*(Keep this to the fewest screens possible; combine screens if the UX stays clean.)*

---

## Task lifecycle rules
### Default rollover
At day rollover:
- Any incomplete tasks in Morning/Afternoon/Evening → **Backlog**
- Completed tasks remain in history (not cluttering Backlog)

### Task-level overrides (optional)
A task can specify:
- **Auto-carry**: yes/no
- **Expire after date** (drop automatically or prompt)
- **Sticky** (stays in its region until done)

### Settings-level behavior (optional)
- Backlog accumulation: on/off
- Prompt before carry-over: on/off
- Lock Complementary until Must-Do: on/off

---

## Calendar integration (target)
### MVP (read-only)
- Pull calendar events via **EventKit**
- Show schedule context within Today + Region views
- Highlight free time windows per region

### Later (write)
- Create time blocks for tasks
- “Schedule Must-Do” button: suggests a block in the region

---

## Notifications (MVP)
- Morning summary: today’s regions + Must-Dos
- Region transition nudges (optional):
  - If Morning Must-Do isn’t started by a chosen time
- End-of-day review prompt:
  - “Review unfinished tasks → Backlog / Reschedule”

All notifications should be **gentle, configurable, and minimal**.

---

## UX principles (non-negotiable)
- **Minimal & calm**: no clutter, no visual noise
- **Intentional constraints**: 1–3–5 is the feature, not a limitation
- **Fast capture**: add a task in one gesture; edit later if needed
- **Focus-first**: the app should bias the user toward finishing the region Must-Do
- **Defaults > settings**: the app should work well without configuration

---

## Data model (conceptual)
### Entities
- **Task**
  - `id`
  - `title`
  - `notes` (optional)
  - `region`: `morning` | `afternoon` | `evening` | `backlog`
  - `bucket`: `must` | `complementary` | `misc` | `backlog` (or `none`)
  - `status`: `todo` | `doing` | `done`
  - `planned_date` (optional; for region tasks)
  - `created_at`, `updated_at`
  - `carry_count`
  - overrides: `auto_carry`, `sticky`, `expires_at` (optional)

- **DayPlan**
  - `date`
  - region slots:
    - `morning_must_task_id`, `morning_complementary_ids` (<=3), `morning_misc_ids` (<=5)
    - same for afternoon, evening

- **History (optional)**
  - completed tasks by date/region (kept lightweight)

---

## Non-goals (initially)
- Heavy project management (kanban boards, deep nesting, dependency graphs)
- Collaboration/team workspaces
- Gamification overload
- Endless customization/theming

---

## Stretch ideas (post-MVP)
- Widgets (Today Regions)
- Siri shortcuts (“Add to Morning Misc”)
- Auto-suggestions: pull from Backlog based on patterns
- Focus timer tied to Must-Do
- Weekly review that stays minimal

---

## Definition of “done” (MVP success)
A user can:
1. Plan Morning/Afternoon/Evening with the **1–3–5** constraint
2. Work through regions in a focused way
3. Have unfinished tasks reliably move to **Backlog**
4. Pull tasks from Backlog back into a region quickly
5. See calendar events for context and receive basic notifications

**If Charstack consistently helps users complete their region Must-Dos, it’s working.**
