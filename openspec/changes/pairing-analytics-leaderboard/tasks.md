## 1. Plugin page and controls

- [x] 1.1 Add `"Leaderboards"` to `PageNames` in `plugin.lua`
- [x] 1.2 Add Leaderboards controls in `controls.lua`: summary labels (count, total time, avg time, time saved), fastest-10 text/list, slowest-10 text/list, by-device-type text/list, Reset Stats button

## 2. Leaderboards layout (arcade style)

- [x] 2.1 Add Leaderboards page branch in `layout.lua` with dark panels and high-contrast accent colors
- [x] 2.2 Layout **HIGH SCORES** summary section (device count, total time, avg per device)
- [x] 2.3 Layout **TOP 10 FASTEST** and **TOP 10 SLOWEST** side-by-side or stacked ranking panels
- [x] 2.4 Layout **BY DEVICE TYPE** panel with rank, model, count, avg, fastest, slowest columns
- [x] 2.5 Layout **TIME SAVED** display and **Reset Stats** button

## 3. Pairing analytics runtime

- [x] 3.1 Add in-memory `PairingRecords` table and in-flight attempt state in `runtime.lua`
- [x] 3.2 Implement `startPairingAttempt(name, model, location)` using `Timer.Now()`
- [x] 3.3 Implement `finishPairingAttempt(outcome)` computing duration via `Timer.Now() − startTime`
- [x] 3.4 Implement session aggregates: total count, total time, average time
- [x] 3.5 Implement fastest-10 and slowest-10 sorting from records
- [x] 3.6 Implement per-model rollups: count, total, avg, fastest, slowest per device type
- [x] 3.7 Implement device-type ranking sorted by average duration (tie-break by count)
- [x] 3.8 Implement time-saved calculation: `(count × 180) − totalSeconds` with hr/min formatting
- [x] 3.9 Implement `resetPairingAnalytics()` and wire to Reset Stats button

## 4. Pairing flow integration

- [x] 4.1 Call `startPairingAttempt` from `OneShotPairingMode(true)` with queue name, model, location
- [x] 4.2 Call `startPairingAttempt` from `PairingMode(true)` on Main UI path
- [x] 4.3 Call `finishPairingAttempt("success")` from `setPeripheral` HTTP 200 callback when ID pairing was armed
- [x] 4.4 Call `finishPairingAttempt("failure")` from `setPeripheral` non-200 callback and pairing timeout paths
- [x] 4.5 Discard in-flight attempt when Pair With ID disarms without terminal outcome
- [x] 4.6 Call `refreshLeaderboardDisplay()` after each finish and after reset

## 5. Leaderboard display refresh

- [x] 5.1 Implement `refreshLeaderboardDisplay()` to populate all Leaderboards controls from aggregates
- [x] 5.2 Format fixed-width arcade-style strings for fastest/slowest device rows
- [x] 5.3 Format by-device-type rows with rank, model, count, avg, fastest, slowest
- [x] 5.4 Handle empty session state (zero devices, placeholder text)

## 6. Documentation and build

- [x] 6.1 Update `README.md` with Leaderboards tab, analytics timing, 3-min benchmark, device-type rankings, screenshot workflow
- [x] 6.2 Regenerate `FastDeploy.qplug` from updated sources
