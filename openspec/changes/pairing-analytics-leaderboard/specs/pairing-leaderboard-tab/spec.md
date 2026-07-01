## ADDED Requirements

### Requirement: Dedicated Leaderboards plugin page
The plugin SHALL expose a separate page tab named **"Leaderboards"** in addition to existing plugin pages.

#### Scenario: Leaderboards tab available
- **WHEN** the operator opens the Fast Deploy plugin
- **THEN** a **Leaderboards** tab is available alongside other plugin pages

### Requirement: Arcade-style leaderboard presentation
The Leaderboards page SHALL use a 1980s arcade high-score visual style: dark panel backgrounds, high-contrast accent colors (e.g., cyan, yellow, magenta on black/dark blue), and fixed-width column alignment suitable for screenshots shared on the Q-SYS community page.

#### Scenario: Screenshot-friendly layout
- **WHEN** the operator views the Leaderboards tab
- **THEN** summary stats and ranking tables are readable at a glance without scrolling for typical session sizes (≤100 devices)
- **AND** text uses consistent column padding for rank, name, model, and time columns

### Requirement: Session summary display
The Leaderboards page SHALL display a session summary including: total devices paired (completed attempts), total pairing time, and average time per device.

#### Scenario: Summary after pairing session
- **WHEN** the operator navigates to Leaderboards after pairing 15 devices in 180 s total
- **THEN** the summary shows 15 devices, 180 s total, and 12 s average per device

### Requirement: Fastest and slowest device tables
The Leaderboards page SHALL display **TOP 10 FASTEST** and **TOP 10 SLOWEST** individual devices for the current session. Each row SHALL show rank, inventory name, device type (model), and duration.

#### Scenario: Fastest devices table populated
- **WHEN** the session has pairing records
- **THEN** the fastest table lists up to 10 devices sorted by shortest duration first

#### Scenario: Slowest devices table populated
- **WHEN** the session has pairing records
- **THEN** the slowest table lists up to 10 devices sorted by longest duration first

### Requirement: By device type ranking panel
The Leaderboards page SHALL display a **BY DEVICE TYPE** section ranking models from fastest average pairing time to slowest average pairing time. Each row SHALL show rank, model name, attempt count, average time, fastest single time, and slowest single time for that type.

#### Scenario: Device types ranked by average speed
- **WHEN** NM-T1 averages 10 s over 8 attempts and NC-110 averages 18 s over 5 attempts
- **THEN** NM-T1 appears above NC-110 in the device-type ranking
- **AND** each row shows count and avg/fastest/slowest for that model

#### Scenario: Multiple types in one session
- **WHEN** the session includes pairings for three or more distinct models
- **THEN** all models with at least one completed attempt appear in the device-type panel sorted by average duration ascending

### Requirement: Time saved display
The Leaderboards page SHALL display **TIME SAVED** computed from the 180 s per device benchmark, formatted in minutes and as hours and minutes (e.g., `280 min (4 hr 40 min)`).

#### Scenario: Time saved shown after rollout
- **WHEN** 100 devices were paired in 1200 s total
- **THEN** the Time Saved display shows approximately 280 minutes saved relative to the 300-minute benchmark

### Requirement: Reset Stats control
The Leaderboards page SHALL include a **Reset Stats** button that clears session analytics and refreshes all leaderboard displays to an empty state.

#### Scenario: Operator resets leaderboard
- **WHEN** the operator presses Reset Stats on the Leaderboards tab
- **THEN** all summary, fastest, slowest, device-type, and time-saved displays reset
- **AND** pairing functionality on other tabs is unaffected

### Requirement: Leaderboard refresh on pairing completion
Leaderboard displays SHALL update when a pairing attempt completes (success or failure) without requiring the operator to change tabs or press refresh.

#### Scenario: Live update after pair
- **WHEN** a pairing attempt completes while the operator is on another tab
- **THEN** navigating to Leaderboards shows the updated counts and rankings
