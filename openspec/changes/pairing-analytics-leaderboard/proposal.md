## Why

Fast Deploy operators pairing dozens of devices per room have no visibility into how fast they are working or how much time the plugin saves compared to manual pairing. Measuring per-device and session-level pairing speed—and presenting it in a fun, shareable leaderboard—will motivate field teams, surface performance outliers, and quantify the value of ID-mode one-shot workflows for community rankings and bragging rights.

## What Changes

- Add **pairing analytics** that start a timer when **Pair With ID** is pressed and stop on pairing **success** or **failure**, using `Timer.Now()` for start and end timestamps
- Record each completed pairing attempt with inventory name, model, location (when available), duration in seconds, and outcome (success/failure)
- Maintain **session aggregates**: total devices paired, total elapsed pairing time, average time per device, fastest 10, slowest 10
- Maintain **per device-type aggregates** grouped by inventory model (e.g., NM-T1, NC-110): count, average time, fastest, and slowest for each type; rank device types by average pairing speed to show which types pair fastest and slowest overall
- Add a **Time Saved** counter using a **3-minute (180 s) per device** manual-pairing benchmark: `timeSaved = (deviceCount × 180) − totalPairingSeconds`, displayed in minutes and as `X hours Y minutes`
- Add a new plugin page/tab **"Leaderboards"** with a **1980s arcade high-score** visual style optimized for screenshots (high contrast, monospace-style ranking columns, initials-style headers) so operators can post rankings to the Q-SYS community page
- Display session summary on the Leaderboards tab: device count, total time, average per device, top 10 fastest, top 10 slowest, time saved, and a **By Device Type** panel ranking models from fastest average to slowest average (with count and avg time per type)
- Wire analytics into both **Pair by ID** one-shot flow and legacy **Main UI** ID pairing (any path where Pair With ID arms pairing)
- Add a **Reset Stats** control on the Leaderboards tab to clear session analytics for a fresh run
- Update README with Leaderboards tab and analytics behavior

## Capabilities

### New Capabilities

- `pairing-analytics`: Timer-based capture of per-device pairing duration from Pair With ID press through success/failure; session aggregation (totals, averages, ranked lists) and per-device-type rollups (count, average, fastest, slowest per model)
- `pairing-leaderboard-tab`: Dedicated Leaderboards plugin page with retro arcade presentation, summary stats, fastest/slowest device tables, device-type speed rankings, time-saved display, and reset control

### Modified Capabilities

- `oneshot-pairing-queue`: Pair With ID one-shot arming SHALL start pairing analytics timer; success/failure in `setPeripheral` SHALL finalize the current device record and update aggregates
- `pair-by-id-tab`: No layout requirement changes; analytics hooks are runtime-only (Pair With ID button behavior unchanged visually)

## Impact

- `plugin.lua` — add `"Leaderboards"` to `PageNames`
- `controls.lua` — new read-only labels/list boxes for leaderboard display and Reset Stats button
- `layout.lua` — new Leaderboards page with arcade-styled layout (colors, fonts, grouped ranking panels)
- `runtime.lua` — analytics state, `Timer.Now()` start/stop in `OneShotPairingMode`/`PairingMode` and `setPeripheral` success/failure paths; leaderboard refresh helpers
- `README.md` — document analytics, benchmark formula, and screenshot workflow
- Compiled `.qplug` artifact regenerated after source changes
