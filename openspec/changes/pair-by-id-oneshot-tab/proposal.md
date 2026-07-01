## Why

Deploying multiple Q-SYS peripherals via ID-mode pairing is a common Fast Deploy workflow, especially from a UCI in the field. Today, Pair by ID lives on the crowded Main UI tab and requires the operator to manually re-select each inventory item after every successful pairing. A dedicated tab with a one-shot queue mode will streamline room-by-room rollouts: pair one device, confirm success, and automatically advance to the next inventory item without leaving the pairing flow.

## What Changes

- Add a new plugin page/tab **"Pair by ID"** dedicated to ID-mode pairing
- Remove the Pair by ID section from the **Main UI** tab (standard name-based pairing remains unchanged)
- Introduce **one-shot queue mode**: operator selects a model, starts a queue of inventory names, arms pairing with a button, presses the physical ID button on the device, and on success the UI automatically advances to the next unpaired inventory item
- When **Location** and **Model** are selected, disable the Name combo and auto-populate **To Be Paired** from `Design.GetInventory()` filtered by `.Location` then `.Model`, collecting `.Name` (name only in lists — location already selected)
- Add **Next Up** display, **To Be Paired** list, and **Paired** list per operator mockup
- **Pair With ID** operates as a one-shot button: press when ready, pair one device, auto-advance on success
- Add UI controls for queue progress (current item, position in queue, status/instructions)
- Extend runtime logic to map inventory names to locations, build filtered queues, and advance the pairing queue on successful assignment
- Update README to document the new tab and one-shot workflow

## Capabilities

### New Capabilities

- `pair-by-id-tab`: Dedicated plugin page for ID-mode pairing with focused layout, directions, and status display
- `oneshot-pairing-queue`: Sequential queue workflow that arms ID pairing one device at a time and auto-advances on success
- `inventory-location-filter`: Location combo filter, name-to-location mapping from design inventory, pending/paired list boxes

### Modified Capabilities

<!-- No existing specs in openspec/specs/ — this is the first spec for this project -->

## Impact

- `plugin.lua` — add `"Pair by ID"` to `PageNames`
- `layout.lua` — new page layout; remove Pair by ID controls from Main UI
- `controls.lua` — new controls for one-shot queue (progress, current device, start queue, location filter, pending/paired lists)
- `runtime.lua` — extend `updateInventory()` to capture `Location` from `Design.GetInventory()`, queue state, location-filtered queue build, list box updates, integration with existing `PairingMode`, `listenForIDMode`, and `setPeripheral` success path
- `README.md` — updated pages list and ID-mode usage instructions
- Compiled `.qplug` artifact regenerated via existing build task after source changes
