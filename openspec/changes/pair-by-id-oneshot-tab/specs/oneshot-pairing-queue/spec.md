## ADDED Requirements

### Requirement: Queue builds automatically from location and model
The one-shot queue SHALL be built automatically when the operator selects both a location and a model on the Pair by ID tab. No separate Start Queue button is required. The queue is the ordered list of `.Name` values from `Design.GetInventory()` matching the selected `.Location` and `.Model`.

#### Scenario: Queue populates on location and model selection
- **WHEN** the operator selects a location and then a model on the Pair by ID tab
- **THEN** the system builds the queue from matching inventory names
- **AND** populates the To Be Paired list
- **AND** clears the Paired list for the new session
- **AND** sets the Next Up display to the first queue item

#### Scenario: Empty filter produces no queue
- **WHEN** the operator selects a location and model with no matching inventory items
- **THEN** the To Be Paired list is empty
- **AND** the Next Up display indicates no devices to pair
- **AND** the Pair With ID button is disabled

### Requirement: One-shot Pair With ID button
The **Pair With ID** button on the Pair by ID page SHALL operate in one-shot mode: each press arms ID pairing for exactly one queue item (the name shown in Next Up). The operator presses the button when ready, then presses the physical ID button on the device.

#### Scenario: Operator arms one-shot pairing
- **WHEN** the queue has items and the operator presses **Pair With ID**
- **THEN** the system sets the inventory name to the Next Up item
- **AND** enables ID pairing mode
- **AND** begins polling discovered devices of the matching model for `id_mode=on`
- **AND** displays directions indicating the operator should press the physical ID button on the device

#### Scenario: Pair With ID disabled when queue empty
- **WHEN** the To Be Paired list is empty
- **THEN** the Pair With ID button is disabled

### Requirement: Automatic queue advance on success
On successful pairing of the current queue item via ID mode, the system SHALL disarm **Pair With ID**, move the name from To Be Paired to Paired, advance to the next queue item, and update the Next Up display.

#### Scenario: Successful pairing advances queue
- **WHEN** ID-mode pairing completes successfully for the current queue item
- **THEN** the system disarms Pair With ID
- **AND** moves the paired name from To Be Paired to Paired
- **AND** advances to the next queue item
- **AND** updates the Next Up display to the next name
- **AND** leaves the operator ready to press Pair With ID again for the next device

#### Scenario: Queue completion
- **WHEN** the last item in the queue is paired successfully
- **THEN** the system displays a completion status message in Next Up or the status log
- **AND** disarms Pair With ID
- **AND** the To Be Paired list is empty

### Requirement: Failed pairing does not advance queue
If ID-mode pairing fails (network error, configuration rejected, or timeout), the system SHALL NOT advance the queue and SHALL keep the current item in Next Up so the operator can retry.

#### Scenario: Pairing failure retains current item
- **WHEN** a pairing attempt for the current queue item fails
- **THEN** the queue index remains unchanged
- **AND** the name stays in To Be Paired and Next Up
- **AND** the failure is shown in the status log
- **AND** the operator may press Pair With ID again to retry

### Requirement: DHCP default for one-shot pairing
One-shot ID-mode pairing SHALL use DHCP (auto IP mode) for device assignment, consistent with the existing ID-mode behavior on Main UI.

#### Scenario: One-shot pairing uses DHCP
- **WHEN** a queue item is paired successfully via one-shot ID mode
- **THEN** the peripheral is configured with DHCP/auto IP mode
