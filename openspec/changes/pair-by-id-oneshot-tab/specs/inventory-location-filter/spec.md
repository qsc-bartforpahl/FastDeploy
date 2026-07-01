## ADDED Requirements

### Requirement: Inventory filtered by Location then Model then Name
The system SHALL build inventory lists from `Design.GetInventory()` using a three-step filter: first by `.Location`, then by `.Model`, then collecting `.Name` for each matching entry.

Per the [Q-SYS Design API](https://help.qsys.com/Content/Control_Scripting/Using_Lua_in_Q-Sys/Design.htm), each inventory entry provides `.Name`, `.Model`, `.Location`, `.Type`, and `.Status`. Only entries where `Location` matches the selected location AND `Model` matches the selected model SHALL appear in the To Be Paired list.

#### Scenario: Filter applies Location then Model then Name
- **WHEN** the operator selects a location and model on the Pair by ID tab
- **THEN** the system queries `Design.GetInventory()` for items where `v.Location` equals the selected location and `v.Model` equals the selected model
- **AND** collects `v.Name` from each matching entry into the To Be Paired list in design inventory order

#### Scenario: Inventory update maintains location indexes
- **WHEN** `updateInventory()` processes `Design.GetInventory()` entries
- **THEN** each inventory name is indexed by its `.Location` and `.Model`
- **AND** location combo choices reflect unique `.Location` values for supported peripheral types

### Requirement: Location and Model selection on Pair by ID page
The Pair by ID page SHALL provide **Location** and **Model** combo boxes in the Inventory group. Both SHALL be selected before the To Be Paired list is populated and before one-shot pairing can proceed.

#### Scenario: Location choices update with design inventory
- **WHEN** design inventory is refreshed via the existing inventory timer
- **THEN** the Location combo box choices reflect unique `.Location` values from `Design.GetInventory()`

#### Scenario: Model choices scoped to location
- **WHEN** the operator selects a location
- **THEN** the Model combo box choices are limited to models that have at least one inventory item at that location

### Requirement: Name combo disabled when location workflow active
When a location is selected on the Pair by ID page, the **Name** combo box SHALL be disabled. The operator SHALL NOT manually select individual inventory names; names come from the filtered To Be Paired list instead.

#### Scenario: Location selected disables Name combo
- **WHEN** the operator selects a location on the Pair by ID tab
- **THEN** the Name combo box is disabled
- **AND** the To Be Paired list is populated once a model is also selected

### Requirement: List boxes show name only
The **To Be Paired** and **Paired** list boxes SHALL display inventory `.Name` values only — not location, model, or other fields — because the operator has already selected the location (and model) via the Inventory filters.

#### Scenario: Pending list shows names only
- **WHEN** the To Be Paired list is populated after location and model selection
- **THEN** each list entry displays only the inventory name (e.g., `nm-t1-a1b2`)
- **AND** does not repeat the location or model in the list text

#### Scenario: Paired list shows names only
- **WHEN** a device is successfully paired and added to the Paired list
- **THEN** only the inventory name is appended to the Paired list

### Requirement: To Be Paired list box
The Pair by ID page SHALL display a **To Be Paired** list box (right column, left side) showing inventory names matching the selected location and model that have not yet been paired in the current session.

#### Scenario: To Be Paired populated when location and model selected
- **WHEN** the operator selects both a location and a model
- **THEN** the To Be Paired list is populated with names from `Design.GetInventory()` filtered by that location and model
- **AND** the first name is shown in the Next Up display

#### Scenario: To Be Paired updates after successful pairing
- **WHEN** a queue item is paired successfully
- **THEN** that name is removed from the To Be Paired list
- **AND** the Next Up display shows the next remaining name

### Requirement: Paired list box
The Pair by ID page SHALL display a **Paired** list box (right column, right side) accumulating inventory names successfully paired during the current session.

#### Scenario: Successful pairing adds to Paired list
- **WHEN** ID-mode pairing completes successfully for a queue item
- **THEN** the inventory name is appended to the Paired list
- **AND** the name is removed from the To Be Paired list

#### Scenario: New filter selection clears session paired list
- **WHEN** the operator changes the selected location or model (starting a new filter scope)
- **THEN** the Paired list is cleared
- **AND** the To Be Paired list is rebuilt from the new location + model filter

### Requirement: Next Up display
The Pair by ID page SHALL include a **Next Up** read-only display showing the inventory name currently targeted for the next one-shot pairing action.

#### Scenario: Next Up shows first item after filter
- **WHEN** location and model are selected and the To Be Paired list is populated
- **THEN** the Next Up display shows the first name in the To Be Paired list

#### Scenario: Next Up advances after success
- **WHEN** a pairing completes successfully
- **THEN** the Next Up display updates to the next name in the To Be Paired list
- **OR** shows a completion message when no names remain
