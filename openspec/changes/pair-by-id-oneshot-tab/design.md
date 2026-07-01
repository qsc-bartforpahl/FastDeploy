## Context

Fast Deploy is a Q-SYS Lua plugin for pairing design inventory items to discovered network peripherals. ID-mode pairing already exists on the **Main UI** tab: the operator toggles **Pair With ID**, selects model and name, and the runtime polls devices via `listenForIDMode()` until a physical ID button press sets `id_mode=on`, then calls `applyAssign()`. On success, `setPeripheral()` clears inventory selection and toggles pairing off.

The operator wants a dedicated **Pair by ID** tab with **one-shot queue mode** for sequential rollouts (e.g., pairing 15 mics in a room without manually re-selecting each inventory name). Operators often deploy per-room using the **Location** field set on inventory items in Q-SYS Designer — exposed via `Design.GetInventory().Location` ([Design API](https://help.qsys.com/Content/Control_Scripting/Using_Lua_in_Q-Sys/Design.htm)).

**Constraints:**
- Q-SYS plugin framework: shared controls across pages, page-specific layout in `layout.lua`
- Existing functions to reuse: `PairingMode()`, `listenForIDMode()`, `applyAssign()`, `setPeripheral()`, `Inventory.ByModel`
- Inventory data source: `Design.GetInventory()` returns `.Name`, `.Model`, `.Location`, `.Type`, `.Status` per item
- Must work on UCI (Reflect Enterprise Manager) — large touch targets, minimal steps
- No new external dependencies

## Goals / Non-Goals

**Goals:**
- Add `"Pair by ID"` page to `PageNames` with focused layout
- Remove ID pairing UI from Main UI (keep standard Assign workflow)
- Implement queue state: build from `Inventory.ByModel[model]` or `Inventory.ByModelAndLocation[model][location]`, arm one item, advance on success
- Add location filter combo populated from `Design.GetInventory().Location`
- When location selected: disable `InventoryName` combo, auto-populate pending list
- Maintain pending and paired list boxes updated on queue start and each success
- Reuse existing `PairWithID` toggle and `listenForIDMode` polling — extend, don't rewrite
- Show progress (current name, index/total) and status in existing debug area

**Non-Goals:**
- Filtering queue by `Status.Code` (paired vs unpaired on core) — session paired list is the source of truth for this workflow
- Static IP configuration during one-shot queue
- Changes to Network Device List or Extra Stuff pages
- Pin-level API changes for external automation of the queue

## Decisions

### 1. New page in `PageNames`, not a sub-panel on Main UI

**Choice:** Add `"Pair by ID"` as a fourth plugin page.

**Rationale:** Matches operator mental model ("I'm in ID pairing mode now") and frees Main UI layout. Q-SYS plugins already support multi-page via `GetPages()`.

**Alternative considered:** Collapsible section on Main UI — rejected because Main UI is already dense and the one-shot workflow needs dedicated space for progress/directions.

### 2. Reuse existing controls where possible; add minimal new controls

**Choice:**
| Control | Purpose |
|---------|---------|
| `InventoryModel` (existing) | Model selection on Pair by ID page |
| `PairWithID` (existing) | Arm/disarm ID pairing for current queue item |
| `Get` (existing) | Refresh discovered devices |
| `PairWithIdDirections` (existing) | Step directions and warnings |
| `PairingByNameDebug` (existing) | Status log |
| `InventoryLocation` (new, List) | Location filter; choices from `Design.GetInventory().Location` |
| `OneShotNextUp` (new, Text, read-only) | **Next Up** — current target name |
| `OneShotToBePaired` (new, List) | **To Be Paired** — remaining names (name only) |
| `OneShotPaired` (new, List) | **Paired** — completed names this session (name only) |
| `InventoryName` (existing) | Disabled when `InventoryLocation` has a value |

**Rationale:** Reusing `PairWithID` keeps `PairingMode()` and `listenForIDMode()` integration intact. New controls are display-only or a single action button — no duplicate pairing logic.

**Alternative considered:** Separate `OneShotPairWithID` control — rejected to avoid diverging pairing code paths.

### 3. Extend `Inventory` table with location lookups

**Choice:** In `updateInventory()`, capture location alongside existing model/name indexing:

```lua
Inventory.NameToLocation = {}           -- name -> location string
Inventory.Locations = {""}              -- unique locations for combo choices
Inventory.LocationsLookup = {}
Inventory.ByModelAndLocation = {}       -- model -> location -> { names }
```

Populate from each `Design.GetInventory()` entry:
```lua
local model, name, location = v.Model, v.Name, v.Location or ""
Inventory.NameToLocation[name] = location
-- index into ByModelAndLocation[model][location]
```

**Rationale:** Matches existing `Inventory.ByModel` pattern. Location comes directly from the [Q-SYS Design API](https://help.qsys.com/Content/Control_Scripting/Using_Lua_in_Q-Sys/Design.htm) — no secondary lookup needed.

### 4. List boxes via Text controls with List constraint

**Choice:** Define `OneShotToBePaired` and `OneShotPaired` as `ControlType = "Text"` with `Constraint = "List"`, laid out with `Style = "Listbox"` in `layout.lua`. Display **name only** in `.Choices` — location and model are already selected in the Inventory filters.

**Rationale:** Consistent with existing plugin controls (`InventoryModel`, `AssignToDevice` use List constraint). Q-SYS plugin framework does not use a separate ListBox control type.

### 5. Queue state in Lua globals, not persisted

**Choice:** Module-level variables in `runtime.lua`:

```lua
OneShotQueue = {}      -- ordered inventory names
OneShotIndex = 0       -- 0 = inactive; 1..#OneShotQueue = active
OneShotModel = ""      -- model queue was built for
OneShotLocation = ""   -- location filter (empty = all)
OneShotPaired = {}     -- names paired this session (mirrors paired list UI)
```

**Rationale:** Queue is a session-scoped operator workflow; no need to survive plugin reload. Simple and matches existing global style in `runtime.lua`.

### 6. Advance queue in `setPeripheral` success handler

**Choice:** After successful HTTP 200 in `setPeripheral`, if `OneShotIndex > 0`, call `advanceOneShot()` instead of the generic PairWithID toggle-off path.

**Flow:**
```
Select Location → disable Name combo
Select Model → filter Design.GetInventory() by .Location then .Model, collect .Name
  → populate OneShotToBePaired, clear OneShotPaired, set OneShotNextUp to first name
Press PairWithID (one-shot) → PairingMode(true), InventoryName=nextUp, listenForIDMode(model)
Physical ID press → applyAssign → setPeripheral → success
  → advanceOneShot(): name moves ToBePaired→Paired, update OneShotNextUp, PairingMode(false)
  → operator presses PairWithID again when ready
```

**Rationale:** `setPeripheral` is the single success choke point for all pairing modes. Centralizing advance logic avoids missing callbacks.

### 7. Remove Pair by ID from Main UI layout only

**Choice:** Delete the Pair by ID group box, `PairWithID` button placement, and ID directions from the `Main UI` branch in `layout.lua`. Do not remove `PairWithID` control definition from `controls.lua`.

**Rationale:** Control remains available on Pair by ID page and in runtime; Main UI simply doesn't render it.

### 8. `buildDirectionsString()` gets a one-shot branch

**Choice:** When `OneShotIndex > 0`, directions show queue-specific steps (current item, "press ID on device", progress) instead of Main UI's 4-step Assign flow.

**Rationale:** Avoids confusing Assign-related legend text on the Pair by ID page.

### 9. Page layout wireframe (operator mockup)

```
┌─────────────────────────────────────────────────────────────────┐
│ [Caution + directions — always visible at top]                  │
├──────────────────────────┬──────────────────┬───────────────────┤
│ Pair by ID               │                  │  To Be Paired     │
│  [ Pair With ID ]        │                  │  ┌─────────────┐  │
│                          │                  │  │ name-1      │  │
│ Inventory                │                  │  │ name-2      │  │
│  Location [▼]            │                  │  │ name-3      │  │
│  Model    [▼]            │                  │  └─────────────┘  │
│  Name     [▼ disabled]   │     Paired       │                   │
│                          │  ┌─────────────┐ │                   │
│ Next Up                  │  │ name-paired │ │                   │
│  ┌──────────────────┐  │  └─────────────┘ │                   │
│  │ name-1           │  │                  │                   │
│  └──────────────────┘  │                  │                   │
├──────────────────────────┴──────────────────┴───────────────────┤
│ Information (status log)                                        │
└─────────────────────────────────────────────────────────────────┘
```

Filter logic: `Design.GetInventory()` → match `.Location` → match `.Model` → collect `.Name`.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Queue includes already-paired inventory names | Session paired list tracks progress; operator uses location filter to scope per room |
| Empty location string in design | Treat as distinct location `""` or `"Default Location"`; include in location combo |
| Operator arms PairWithID with empty queue | Disable `PairWithID` when To Be Paired list is empty |
| `PairingMode(true)` on Main UI path vs one-shot path diverge | One-shot always sets `InventoryName` before arming; `PairWithID` on Main UI no longer visible so no conflict |
| Inventory list changes mid-queue | Changing location or model rebuilds queue and clears Paired list |
| Success callback races with manual PairWithID press | `advanceOneShot` always disarms first; `RefreshTimer` stopped by existing `listenForIDMode` on detect |
| List box `.Choices` update performance | Only refresh lists on queue start and advance, not every inventory timer tick |

## Migration Plan

1. Implement source changes in `.lua` files
2. Run **Compile QSD Plugin** VS Code task to regenerate `FastDeploy.qplug`
3. Test in Q-SYS Designer: Main UI unchanged for Assign flow; new tab for ID queue
4. Test on UCI if available
5. Update README
6. No breaking pin changes — existing designs load; operators see new tab

**Rollback:** Revert commit; recompile plugin. No data migration.

## Resolved / Open Questions

1. **List display:** Name only in To Be Paired and Paired lists — location is already selected via filter. **Resolved.**
2. **Skip item:** Out of scope for v1; can add **Skip** button later.
3. **Queue trigger:** Queue builds automatically when location + model are selected (no separate Start Queue button). **Resolved per mockup.**
