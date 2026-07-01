## ADDED Requirements

### Requirement: Dedicated Pair by ID plugin page
The plugin SHALL expose a separate page tab named **"Pair by ID"** in addition to the existing Main UI, Network Device List, and Extra Stuff pages.

#### Scenario: Page appears in plugin navigation
- **WHEN** the operator opens the Fast Deploy plugin in Q-SYS Designer or on a UCI
- **THEN** a **"Pair by ID"** tab is available alongside the other plugin pages

### Requirement: Pair by ID page layout matches one-shot workflow
The Pair by ID page SHALL use a focused layout distinct from Main UI, organized as follows:

1. **Top** — ID-mode caution text and step directions (always visible)
2. **Pair by ID** group — **Pair With ID** one-shot button
3. **Inventory** group — **Location**, **Model**, and **Name** combo boxes in a row (Location and Model required for queue workflow)
4. **Next Up** group — read-only display of the inventory name currently targeted for pairing
5. **Right column** — two list boxes side by side: **To Be Paired** (pending) and **Paired** (completed this session)
6. **Bottom** — status/log area (Information)

The Pair by ID page SHALL NOT display Main UI controls: Assign, AssignToDevice, Peripheral IP mode, or Reset Name.

#### Scenario: Operator views Pair by ID page
- **WHEN** the operator navigates to the **Pair by ID** tab
- **THEN** the page shows the caution/directions area, Pair With ID button, Location/Model/Name inventory filters, Next Up display, To Be Paired and Paired lists, and status log
- **AND** standard name-based pairing controls from Main UI are not shown

### Requirement: Pair by ID removed from Main UI
The Main UI page SHALL NOT display the Pair by ID section (Pair With ID button, Pair by ID group box, or ID-mode directions). Standard inventory-to-peripheral pairing by device selection SHALL remain on Main UI unchanged.

#### Scenario: Main UI shows only standard pairing
- **WHEN** the operator navigates to the **Main UI** tab
- **THEN** the Pair With ID button and Pair by ID instructions are not shown
- **AND** the standard pairing workflow (inventory selection, peripheral selection, Assign) remains available

### Requirement: Shared runtime controls across pages
Controls used by both pages (e.g., `InventoryModel`, `PairWithID`, `Get`) SHALL remain single plugin controls whose layout placement differs per page; behavior SHALL be consistent regardless of which page initiated the action.

#### Scenario: Refresh from Pair by ID page
- **WHEN** the operator presses Refresh on the **Pair by ID** tab (if present) or device discovery runs from inventory update
- **THEN** the same device discovery logic runs as on Main UI
- **AND** discovered devices are available for ID-mode pairing

### Requirement: ID-mode safety warnings always visible
The Pair by ID page SHALL display the ID-mode caution text at the top of the page (devices that do not support ID mode, operator-only pairing, risk of pairing unintended devices), not only after arming.

#### Scenario: Caution visible on page load
- **WHEN** the operator opens the **Pair by ID** tab
- **THEN** the caution/warning text is visible in the directions area before any pairing action
