## ADDED Requirements

### Requirement: One-shot pairing records analytics timing
When one-shot **Pair With ID** is armed for a queue item, the system SHALL start pairing analytics timing. When pairing completes successfully or fails for that queue item, the system SHALL finalize the analytics record before queue advance or retry behavior runs.

#### Scenario: Success records analytics then advances
- **WHEN** ID-mode pairing completes successfully for the current one-shot queue item
- **THEN** the system finalizes the pairing analytics record with outcome success
- **AND** then disarms Pair With ID and advances the queue per existing one-shot behavior

#### Scenario: Failure records analytics then retains item
- **WHEN** a pairing attempt for the current one-shot queue item fails
- **THEN** the system finalizes the pairing analytics record with outcome failure
- **AND** the queue index remains unchanged for retry

## MODIFIED Requirements

### Requirement: One-shot Pair With ID button
The **Pair With ID** button on the Pair by ID page SHALL operate in one-shot mode: each press arms ID pairing for exactly one queue item (the name shown in Next Up). The operator presses the button when ready, then presses the physical ID button on the device. Arming SHALL also start pairing analytics timing for that attempt.

#### Scenario: Operator arms one-shot pairing
- **WHEN** the queue has items and the operator presses **Pair With ID**
- **THEN** the system sets the inventory name to the Next Up item
- **AND** enables ID pairing mode
- **AND** begins polling discovered devices of the matching model for `id_mode=on`
- **AND** displays directions indicating the operator should press the physical ID button on the device
- **AND** starts pairing analytics timing using `Timer.Now()`

#### Scenario: Pair With ID disabled when queue empty
- **WHEN** the To Be Paired list is empty
- **THEN** the Pair With ID button is disabled
