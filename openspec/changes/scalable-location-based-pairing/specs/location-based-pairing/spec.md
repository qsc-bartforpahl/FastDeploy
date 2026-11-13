# location-based-pairing Specification

## Requirements

### Requirement: Select inventory items by location, model, and name

The system SHALL provide cascading selectors in the order location, model,
then inventory name.

#### Scenario: Select an inventory location

- **WHEN** Designer inventory data is loaded
- **THEN** the location selector lists locations represented by inventory items
  in case-insensitive alphabetical order
- **AND** the configured behavior for missing or blank inventory location is
  applied

#### Scenario: Filter models and names by location

- **WHEN** the user selects a location
- **THEN** the model selector contains only models represented in the selected
  location
- **AND** the inventory-name selector contains only names for the selected
  location and model
- **AND** each choice list is sorted case-insensitively with a stable
  tie-breaker
- **AND** online peripherals are not filtered by location because they have
  not yet been adopted into a location

#### Scenario: Change a parent selection

- **WHEN** the user changes the selected location
- **THEN** the model and inventory-name selections are cleared and their
  choices are rebuilt for the new location
- **WHEN** the user changes the selected model
- **THEN** the inventory-name selection is cleared and its choices are rebuilt
  for the selected location and model

### Requirement: Navigate inventory names with Prev and Next

The system SHALL provide `Prev Device` and `Next Device` controls that move
through the sorted inventory names available for the selected location and
model, and SHALL keep the inventory-name dropdown synchronized with the
navigated name.

#### Scenario: Advance from the current or just-paired name

- **WHEN** the user activates `Next Device` with a current inventory name
- **THEN** the next name in the selected location/model list becomes the
  inventory-name selection
- **AND** the green success indicator is cleared for a different, not-yet-paired
  name
- **WHEN** a successful pairing cleared the current selection
- **THEN** `Next Device` advances from the last successfully paired name

#### Scenario: Go back to a previous name

- **WHEN** the user activates `Prev Device`
- **THEN** the previous name in the selected location/model list becomes the
  inventory-name selection
- **AND** the inventory-name dropdown reflects that exact name
- **AND** the green success indicator is cleared for a different, not-yet-paired
  name

#### Scenario: Navigate from no cursor

- **WHEN** no current or last-successful inventory name exists in the filtered
  list
- **THEN** `Next Device` selects the first name and `Prev Device` selects the
  last name

#### Scenario: Reach a list boundary

- **WHEN** the first or last name is selected
- **THEN** the corresponding previous or next control is disabled
- **AND** navigation does not wrap around
- **WHEN** the filtered list is empty
- **THEN** both controls are disabled

#### Scenario: Navigation does not pair automatically

- **WHEN** the user activates either navigation control
- **THEN** the system changes only the inventory-name selection
- **AND** it does not assign an inventory item or send a peripheral request

#### Scenario: Change location or model

- **WHEN** the user changes location or model
- **THEN** the navigation cursor and button states are recalculated against the
  new filtered inventory-name list
- **AND** no name from the previous list remains selected unless it is valid
  in the new list

### Requirement: Filter online pairing candidates by model

The system SHALL offer only online peripherals matching the selected inventory
model as candidates for manual assignment and ID-mode pairing. The system SHALL
NOT require a location on an unadopted peripheral.

#### Scenario: Assign to an online peripheral

- **WHEN** a location and inventory model are selected
- **THEN** the peripheral selector contains online peripherals for that
  model, regardless of location
- **AND** selecting an inventory name does not make devices from another
  model eligible

#### Scenario: Inventory location is unavailable

- **WHEN** an inventory item has no usable location metadata
- **THEN** the item is available under `Unassigned`
- **AND** its model and name can still be selected for pairing

### Requirement: Preserve pairing selection validity

The system SHALL invalidate downstream choices and pending ID polling whenever
the location or model selection changes.

#### Scenario: Selection changes during ID polling

- **WHEN** the user changes location, model, name, or exits ID pairing while
  status requests are in flight
- **THEN** late responses from the previous selection SHALL NOT trigger an
  assignment
- **AND** a location change SHALL invalidate model/name choices, but peripheral
  candidates remain filtered only by the newly selected model

### Requirement: Keep the selector usable at scale

The system SHALL build location, model, and name choices from the complete
loaded data set, independently of the configured device-detail display count.

#### Scenario: Discovery exceeds the detail display count

- **WHEN** the Core reports more peripherals than the configured device-detail
  display count
- **THEN** discovery completes without indexing outside the display controls
- **AND** all discovered peripherals remain represented in the pairing
  candidate data
