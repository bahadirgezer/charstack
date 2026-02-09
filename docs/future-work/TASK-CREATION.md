# Design principle (anchor this first)

> **Typing should answer only one question:**
> *“What is the task?”*
>
> Everything else should be inferred, gestured, or optional.

If task creation ever asks the user to *think in steps*, it loses.

---

## 1. Tap-anywhere to add (region-as-input)

### What’s wrong today

* You must target the small bar
* It visually reads as a *form*, not an affordance

### Better: “Empty space is intent”

**Behavior**

* Tapping anywhere inside a region card (or bucket section) opens inline input *at that location*
* The cursor appears exactly where you tapped
* Keyboard slides up immediately

**Why it works**

* Matches iOS Notes & Reminders muscle memory
* Removes UI targeting friction
* Makes regions feel *alive*, not containers

**Bonus**

* Tap inside:

  * Must area → defaults to Must
  * Complementary list → defaults to Complementary
  * Misc list → defaults to Misc

No picker. No decision.

---

## 2. Bucket selection via **directional gestures**, not UI

This is the biggest win.

### Pattern: type → swipe → release

**Flow**

1. User types task title
2. Before hitting return:

   * Swipe **up** → Must
   * Swipe **right** → Complementary
   * Swipe **down** → Misc
3. Release = create task

**Visual feedback**

* Background tint subtly shifts as you swipe
* Haptic tick when crossing into a bucket
* Bucket label briefly appears near cursor

**Why this is excellent**

* Zero UI chrome
* One-handed
* Fast for power users, discoverable for normals
* Feels *very* iOS (mail swipe muscle memory)

You can still show the picker for accessibility—but gestures become the fast path.

---

## 3. Press-and-hold to “pour” tasks into a region

This one’s subtle and powerful.

### Long-press anywhere in a region

**Behavior**

* Long-press on region background
* Keyboard appears
* You can **type multiple lines**
* Each line becomes a task on release

Example:

```
email Sam
review PR
send invoice
```

→ creates 3 Misc tasks by default

**Why this matters**

* Brain dump mode without switching context
* Feels like jotting notes, not task management
* Power users *will* use this constantly

Optional:

* First line auto-Must if region empty
* Or long-press near Must slot biases Must

---

## 4. Inline “promote/demote” via drag, not edit

Creation doesn’t end at creation. Adjustment must be just as fluid.

**Behavior**

* Drag a task vertically across bucket boundaries
* As it crosses:

  * Haptic feedback
  * Bucket label morphs
* Drop = reassigned

**Why this helps creation**

* Users stop caring about choosing perfectly up front
* They’ll dump tasks quickly and refine by feel
* Reduces anxiety during entry

This pairs beautifully with fast, sloppy input.

---

## 5. One global gesture: **pull down to add**

Instead of a + button.

**Anywhere in Today view**

* Pull down slightly
* Inline input appears at the top of the *current region*
* Keyboard follows finger

**Why**

* Matches pull-to-search / pull-to-refresh muscle memory
* No visual clutter
* Works even when scrolling

Power users learn it. Casual users never need to.

---

## 6. Voice—but scoped and opinionated

Voice shouldn’t be “add a task.” That’s generic and unreliable.

### Make it region-aware

Examples:

* “Add to Morning: call Alex”
* “Evening must: write outline”
* “Backlog: idea about onboarding”

**Key rules**

* No confirmations
* No dialog
* Task just appears, lightly animated

This isn’t a primary input. It’s an *escape hatch* when hands are busy.

---

## 7. The “always ready” state (this is psychological)

When the app opens:

* Cursor should be **one tap away**
* No mode switching
* No visual ceremony

Consider:

* First tap anywhere = ready to type
* Keyboard appears faster than expected
* App subtly communicates: *“I’m ready when you are.”*

That alone changes how the app feels.

---

## What NOT to do (important)

Avoid:

* Dedicated “Add Task” screens
* Floating action buttons (Android smell)
* Mandatory priority selection
* Too many visible controls
* Gamified entry (badges, points, etc.)

Your audience doesn’t want help *adding* tasks.
They want **no resistance** between thought → capture.

---

## If I had to bet on a stack (minimal, high impact)

If you only implement **three things**, I’d pick:

1. **Tap-anywhere inline input**
2. **Swipe-to-choose bucket while typing**
3. **Drag to promote/demote after creation**

That alone would make Charstack feel *materially different* from every other task app.

If you want, next we can:

* Sketch a concrete gesture map (what gesture works where)
* Pressure-test discoverability vs power
* Or design the haptics + animations so this feels *Apple-level* instead of gimmicky

