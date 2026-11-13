# scalable-device-discovery Specification

## Requirements

### Requirement: Populate selectors without per-device status reads

The system SHALL populate location, model, and name selectors from loaded
inventory and Core discovery metadata without requesting status XML from every
peripheral.

#### Scenario: Discover a large system

- **WHEN** the Core returns 750 peripherals from discovery
- **THEN** the plugin issues the Core discovery request
- **AND** selector population does not issue 750 per-peripheral
  `/cgi-bin/status_xml` requests

### Requirement: Coalesce automatic rediscovery

The system SHALL avoid overlapping automatic discovery cycles when inventory
status changes trigger refreshes.

#### Scenario: Inventory status changes repeatedly

- **WHEN** inventory updates request device rediscovery while a discovery
  cycle is already active
- **THEN** the system SHALL coalesce the refresh request rather than start an
  overlapping cycle
- **AND** rediscovery SHALL NOT fan out status XML requests to every
  peripheral

### Requirement: Bound peripheral HTTP concurrency

The system SHALL limit concurrent per-peripheral HTTP requests to a fixed
maximum of four that does not grow with the number of discovered peripherals.

#### Scenario: Poll ID state

- **WHEN** ID pairing is active
- **THEN** status checks are scheduled only for candidates matching the
  selected model
- **AND** the selected location is used to narrow Designer inventory choices,
  not the unadopted peripheral candidate set
- **AND** the number of outstanding peripheral requests never exceeds the
  four-request concurrency limit
- **AND** a new poll cycle does not duplicate requests that are still
  outstanding

#### Scenario: Turn off ID mode before scanning

- **WHEN** ID pairing requires clearing ID mode on candidate devices
- **THEN** ID-off commands are limited to devices matching the selected model
  (peripheral location is unavailable before adoption)
- **AND** those commands use the bounded request scheduler
- **AND** polling does not resume as though all commands succeeded if any
  command fails

### Requirement: Read ID state from the peripheral status endpoint

The system SHALL determine whether a peripheral is in ID mode from the
`<id_mode>` element returned by that peripheral's
`/cgi-bin/status_xml` endpoint.

#### Scenario: Detect ID mode

- **WHEN** a candidate's status response contains `<id_mode>on</id_mode>`
- **THEN** the system stops further ID polling and begins pairing that device
- **AND** late responses from other in-flight requests do not start a second
  pairing operation

### Requirement: Keep optional status enrichment bounded

The system SHALL separate optional device status enrichment from discovery and
SHALL NOT start enrichment requests for controls that cannot be displayed.

#### Scenario: Display a bounded device-detail list

- **WHEN** the device-detail display count is lower than the number of
  discovered peripherals
- **THEN** only devices represented by visible detail rows are eligible for
  automatic detail enrichment
- **AND** all discovered devices remain available to the pairing selectors
