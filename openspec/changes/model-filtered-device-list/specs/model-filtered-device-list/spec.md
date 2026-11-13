# model-filtered-device-list Specification

## Requirements

### Requirement: Filter device details by discovered model

The system SHALL provide a model/type filter for the Network Device List using
the model (`part_number`) values from the current Core discovery result.

#### Scenario: Choose a discovered model

- **WHEN** a model is selected in the device-list filter
- **THEN** the visible device list contains only discovered peripherals whose
  model matches that selection
- **AND** device names are displayed in deterministic,
  case-insensitive-sorted order
- **AND** the pairing workflow and its location/model/name selectors are not
  changed by this filter

#### Scenario: Show all discovered models

- **WHEN** `All Models` is selected
- **THEN** the filtered result contains all peripherals in the current
  discovery catalog before the display limit is applied

### Requirement: Reuse the current discovery catalog for filtering

The system SHALL apply model-filter changes locally to the latest successful
Core discovery result and SHALL NOT request Core rediscovery solely because the
filter changed.

#### Scenario: Change the filter

- **WHEN** the operator changes the selected model
- **THEN** the system filters the cached discovery catalog
- **AND** it does not send a Core discovery HTTP request
- **AND** an explicit Refresh action remains available to request a new
  discovery result

#### Scenario: Discovery request fails

- **WHEN** an explicit discovery request fails
- **THEN** the system SHALL report the failure
- **AND** it SHALL NOT replace the last successful catalog with an empty
  success-shaped result

### Requirement: Bound displayed device rows per model

The system SHALL display no more than 150 matching peripherals in the Network
Device List, further limited by the configured Device Count property.

#### Scenario: Configure the maximum number of rows

- **WHEN** the Device Count property is configured
- **THEN** its allowed range SHALL be 1 through 150
- **AND** the default row count SHALL remain unchanged
- **AND** no more than the configured number of matching devices is rendered

#### Scenario: More than 150 devices match

- **WHEN** the selected model has more than 150 discovered matches
- **THEN** the system SHALL display the first 150 matches in deterministic
  name order, subject to the configured Device Count
- **AND** it SHALL show the total number of matching devices and the number
  displayed
- **AND** it SHALL clearly warn that additional matching devices are not
  shown
- **AND** all discovered devices remain in the discovery catalog and
  available to pairing

### Requirement: Enrich only displayed device rows

The system SHALL request peripheral status XML only for devices displayed in
the current device-list view.

#### Scenario: Select a model with many matches

- **WHEN** a filter selects a model with more matches than displayed rows
- **THEN** automatic detail reads are queued only for the displayed matches
- **AND** detail requests use the existing limit of at most four concurrent
  per-peripheral HTTP requests
- **AND** undisplayed matches do not receive detail requests solely to
  populate the device list

#### Scenario: Change filters while detail requests are pending

- **WHEN** the operator changes the model filter while detail reads are
  queued or in flight
- **THEN** queued detail work for the previous view SHALL be canceled
- **AND** late responses for the previous view SHALL NOT update rows in the
  new view
- **AND** detail reads for the newly displayed rows SHALL remain within the
  four-request concurrency limit

### Requirement: Preserve complete discovery data

The system SHALL keep the full successful Core discovery catalog independent
of the selected filter and displayed row count.

#### Scenario: Filter a large discovery result

- **WHEN** the Core reports more devices than the displayed row limit
- **THEN** changing the model filter SHALL NOT discard devices outside the
  current model
- **AND** those devices remain available after selecting another model or
  `All Models`
