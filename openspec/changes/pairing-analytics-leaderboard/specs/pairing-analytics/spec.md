## ADDED Requirements

### Requirement: Pairing timer starts on Pair With ID press
When the operator arms ID pairing by pressing **Pair With ID**, the system SHALL record a start timestamp using `Timer.Now()` and SHALL associate the in-flight attempt with the current inventory name, model (device type), and location (when available).

#### Scenario: One-shot queue arms pairing
- **WHEN** the operator presses **Pair With ID** on the Pair by ID tab and one-shot mode activates
- **THEN** the system stores `Timer.Now()` as the attempt start time
- **AND** captures the Next Up inventory name, selected model, and selected location

#### Scenario: Main UI arms pairing
- **WHEN** the operator presses **Pair With ID** on the Main UI tab and ID pairing mode activates
- **THEN** the system stores `Timer.Now()` as the attempt start time
- **AND** captures the current inventory name and model when set

#### Scenario: Disarm without completion discards attempt
- **WHEN** the operator disarms Pair With ID before a success or failure outcome
- **THEN** the system SHALL NOT record a pairing attempt for that arming cycle

### Requirement: Pairing timer stops on success or failure
The system SHALL stop the in-flight pairing timer when the attempt reaches a terminal outcome: successful configuration in `setPeripheral` (HTTP 200) or failed configuration (non-200 response or pairing timeout that aborts the attempt).

#### Scenario: Successful pairing records duration
- **WHEN** `setPeripheral` completes successfully for an armed ID pairing attempt
- **THEN** the system computes duration as `Timer.Now() − startTime` in seconds
- **AND** appends a record with outcome `success`

#### Scenario: Failed pairing records duration
- **WHEN** `setPeripheral` fails or a pairing timeout aborts an armed ID pairing attempt
- **THEN** the system computes duration as `Timer.Now() − startTime` in seconds
- **AND** appends a record with outcome `failure`

### Requirement: Per-device pairing record fields
Each completed pairing attempt SHALL be stored with: inventory name, model (device type), location (empty string if unset), duration in seconds (one decimal place minimum for display), and outcome (`success` or `failure`).

#### Scenario: Record includes device type
- **WHEN** a pairing attempt completes for inventory name "Mic-01" with model "NM-T1"
- **THEN** the stored record includes `model = "NM-T1"`
- **AND** the record is available for per-device and per-type aggregation

### Requirement: Session aggregate statistics
The system SHALL maintain session-level aggregates across all completed attempts in the current plugin runtime session: total device count, total pairing time (seconds), and average time per device (total time ÷ count).

#### Scenario: Aggregates update after each attempt
- **WHEN** a third pairing attempt completes with durations 10 s, 14 s, and 12 s
- **THEN** total count is 3
- **AND** total time is 36 s
- **AND** average time per device is 12 s

### Requirement: Fastest and slowest individual devices
The system SHALL rank completed attempts by duration and expose the **10 fastest** and **10 slowest** individual devices for the current session. Each entry SHALL include rank, inventory name, model, and duration.

#### Scenario: Fastest ten devices
- **WHEN** the session has at least 10 completed attempts
- **THEN** the fastest-10 list contains the ten lowest durations with rank 1 being the shortest time

#### Scenario: Slowest ten devices
- **WHEN** the session has at least 10 completed attempts
- **THEN** the slowest-10 list contains the ten highest durations with rank 1 being the longest time

### Requirement: Per device-type aggregate statistics
The system SHALL group completed attempts by model (device type) and compute for each model: attempt count, total time, average time, fastest single attempt (duration and inventory name), and slowest single attempt (duration and inventory name).

#### Scenario: Multiple devices of same type
- **WHEN** three "NM-T1" devices complete in 8 s, 12 s, and 10 s
- **THEN** the NM-T1 rollup shows count 3, total 30 s, average 10 s, fastest 8 s, slowest 12 s

#### Scenario: Single device of a type
- **WHEN** one "NC-110" device completes in 15 s
- **THEN** the NC-110 rollup shows count 1, average 15 s, fastest 15 s, slowest 15 s

### Requirement: Device-type speed ranking
The system SHALL rank device types (models) by average pairing duration for the session. Types with lower average time SHALL be ranked as faster. The ranking SHALL be used to identify which device types pair fastest and slowest overall.

#### Scenario: Fastest device type
- **WHEN** NM-T1 average is 10 s and NC-110 average is 18 s in the same session
- **THEN** NM-T1 ranks above NC-110 in the fastest-types ordering

#### Scenario: Tie-breaking by count
- **WHEN** two models share the same average duration
- **THEN** the model with more attempts ranks higher (more data confidence)

### Requirement: Time saved benchmark calculation
The system SHALL compute time saved using a fixed manual-pairing benchmark of **180 seconds (3 minutes) per completed attempt**: `timeSavedSec = (attemptCount × 180) − totalPairingSeconds`.

#### Scenario: Time saved example
- **WHEN** 100 completed attempts total 1200 s of pairing time
- **THEN** benchmark time is 18000 s (300 minutes)
- **AND** actual time is 1200 s (20 minutes)
- **AND** time saved is 16800 s (280 minutes, displayed as 4 hr 40 min)

#### Scenario: Slower than benchmark
- **WHEN** total pairing time exceeds the benchmark
- **THEN** the system displays a negative or zero time-saved value indicating no savings (or time over benchmark)

### Requirement: Session reset
The system SHALL provide a way to clear all pairing records and aggregates for a fresh session without affecting pairing functionality.

#### Scenario: Reset clears analytics
- **WHEN** the operator triggers Reset Stats
- **THEN** all pairing records and derived aggregates are cleared
- **AND** leaderboard displays show empty/zero state
