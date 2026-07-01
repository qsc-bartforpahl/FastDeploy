## Context

Fast Deploy already supports ID-mode pairing on Main UI and a dedicated **Pair by ID** tab with one-shot queue mode. Pairing completes in `setPeripheral()` via HTTP response (success on code 200, failure otherwise). There is no timing instrumentation today. Q-SYS Lua provides `Timer.Now()` (seconds, floating point) for high-resolution elapsed-time measurement without managing a running timer object.

Operators want session-level stats for bragging rights and community screenshots, plus insight into which **device types (models)** pair faster or slower in the field.

## Goals / Non-Goals

**Goals:**

- Start a pairing timer when **Pair With ID** is armed (button pressed to begin listening for ID mode)
- Stop the timer on first terminal outcome: HTTP success or failure in `setPeripheral`, or explicit pairing timeout if one fires before `setPeripheral` returns
- Store per-attempt records: inventory name, model (device type), location (if set), duration (seconds), outcome
- Compute session totals, fastest/slowest 10 individual devices, average per device, and **per-model rollups**
- Rank device types by average pairing time (fastest type → slowest type)
- Present everything on a **Leaderboards** tab styled like a 1980s arcade high-score screen, readable in screenshots
- Calculate **Time Saved** vs a 180 s (3 min) manual benchmark per device
- Use `Timer.Now()` exclusively for start/end timestamps

**Non-Goals:**

- Persistent storage across design reloads or Core reboots (session-only, in-memory)
- Cross-site or multi-operator cloud leaderboards
- Analytics for non-ID pairing paths (Assign button, Reset Name, DHCP toggle)
- Historical trends beyond the current session

## Decisions

### 1. Timer start/stop points

**Choice:** Call `PairingAnalytics.startAttempt()` when Pair With ID transitions to armed (`OneShotPairingMode(true)` and `PairingMode(true)` when ID listening begins). Call `PairingAnalytics.finishAttempt(outcome)` from `setPeripheral` HTTP callback on success (200) or failure (non-200), and from any ID pairing timeout handler if pairing aborts without reaching `setPeripheral`.

**Rationale:** Matches operator intent: clock starts when they press Pair With ID and stops when the attempt resolves.

**Alternative considered:** Start on physical ID button detection — rejected because operator prep time before ID press varies and is harder to define consistently.

### 2. Data model (in-memory Lua tables)

**Choice:** Append each finished attempt to `PairingRecords` as:

```lua
{
  name = "Mic-01",
  model = "NM-T1",
  location = "Room A",
  durationSec = 12.4,
  outcome = "success" | "failure",
  finishedAt = Timer.Now()
}
```

Maintain derived session fields updated on each finish:

| Field | Calculation |
|-------|-------------|
| `totalCount` | count of records |
| `totalDurationSec` | sum of `durationSec` |
| `avgDurationSec` | `totalDurationSec / totalCount` |
| `fastest10` / `slowest10` | sort by `durationSec`, take 10 |
| `byModel[model]` | `{ count, totalSec, avgSec, fastest, slowest, fastestName, slowestName }` |

**Rationale:** Simple append + recompute on finish; session sizes are small (tens to low hundreds of devices).

### 3. Per device-type ranking

**Choice:** Group records by `Controls.InventoryModel.String` (or `DeviceTypeLookup` fallback at finish time). For each model with ≥1 record, compute average duration. Sort models ascending by `avgSec` for the **Fastest Types** list and descending for **Slowest Types** list. Display both on Leaderboards (or a single combined table with rank).

**Rationale:** Model is the device-type key operators already select and recognize in the field.

**Alternative considered:** Group by discovered peripheral hardware name — rejected; inventory model is the meaningful deploy unit.

### 4. Time Saved formula

**Choice:**

```
benchmarkSec = deviceCount × 180
timeSavedSec = benchmarkSec − totalDurationSec
```

Display as `MMM min` and `H hr M min` (e.g., 280 min → `4 hr 40 min`). Negative savings (slower than benchmark) show as `0 saved` or `-X min over benchmark` — **show signed value** so operators see when they beat or miss the benchmark.

**Rationale:** Matches user example (100 devices × 180 s = 18000 s benchmark vs 1200 s actual = 16800 s = 280 min saved).

### 5. Leaderboards tab layout (arcade aesthetic)

**Choice:** New page `"Leaderboards"` with:

- Dark background group boxes, bright cyan/yellow/magenta accent text (classic arcade palette)
- Monospace or fixed-width column alignment via padded label strings (`" 1. NM-T1    12.4s  (8 devices)"`)
- Sections: **HIGH SCORES** (summary), **TOP 10 FASTEST**, **TOP 10 SLOWEST**, **BY DEVICE TYPE** (ranked models), **TIME SAVED**
- **Reset Stats** button clears all records and refreshes display
- No scrolling required for typical session sizes; use multiline read-only Text controls or ListBox-style controls

**Rationale:** Screenshot-friendly; operators post to Q-SYS community for rankings.

### 6. Integration hooks

**Choice:**

| Event | Action |
|-------|--------|
| `OneShotPairingMode(true)` | `startAttempt(name, model, location)` |
| `PairingMode(true)` on Main UI | `startAttempt` with current inventory name/model |
| `setPeripheral` success | `finishAttempt("success")` |
| `setPeripheral` failure | `finishAttempt("failure")` |
| Pair With ID disarmed without finish | discard in-flight attempt (no record) |
| Reset Stats | clear all |

After each finish, call `refreshLeaderboardDisplay()`.

### 7. Failures included in averages

**Choice:** Failed attempts count toward totals, fastest/slowest lists, and per-type averages (duration = time until failure).

**Rationale:** User specified timer stops on success **or** failure; failures are real deployment time.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Pair With ID toggled off mid-attempt leaves orphan start | Discard in-flight attempt if disarmed before finish; do not record partial times |
| Model empty on Main UI path | Capture model from `DeviceTypeLookup[peripheralName]` at finish if inventory model unset |
| Large session UI overflow | Cap displayed rows at 10 for device lists; show all types or cap at 10 with highest count first |
| `Timer.Now()` drift across long sessions | Acceptable for relative session timing; not used for wall-clock scheduling |
| Re-pairing same name inflates counts | Accept as separate attempts; Reset Stats starts fresh session |

## Migration Plan

1. Add controls and Leaderboards layout (no behavior change)
2. Add analytics module in `runtime.lua`
3. Wire start/stop hooks into existing pairing paths
4. Test one-shot and Main UI ID flows
5. Regenerate `.qplug`
6. No migration of existing data (new feature)

## Open Questions

- Should only **successful** pairings count toward Time Saved benchmark device count, or all attempts? **Default: all completed attempts (success + failure).**
- Show device-type rankings only for types with ≥2 samples to avoid noisy single-device averages? **Default: show all types with ≥1; optional footnote in UI for n=1.**
