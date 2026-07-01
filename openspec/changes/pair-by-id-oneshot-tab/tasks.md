## 1. Plugin page and controls

- [x] 1.1 Add `"Pair by ID"` to `PageNames` in `plugin.lua` (after Main UI)
- [x] 1.2 Add `InventoryLocation` (List combo) to `controls.lua`
- [x] 1.3 Add `OneShotNextUp` (read-only Text), `OneShotToBePaired` (List), `OneShotPaired` (List) to `controls.lua`

## 2. Layout — Pair by ID page (per mockup)

- [x] 2.1 Remove Pair by ID section from Main UI in `layout.lua`
- [x] 2.2 Add Pair by ID page layout: caution/directions top, Pair With ID button, Inventory group (Location / Model / Name row), Next Up display, To Be Paired + Paired list boxes (right column), Information status log bottom
- [x] 2.3 Verify Main UI unchanged (Assign, Peripheral, IP mode, Reset Name)

## 3. Inventory location data and filter

- [x] 3.1 Extend `Inventory` table with `NameToLocation`, `Locations`, `ByModelAndLocation`, `ModelsByLocation`
- [x] 3.2 Update `updateInventory()` to read `v.Location` from `Design.GetInventory()` and index by Location → Model → Name
- [x] 3.3 Populate `InventoryLocation.Choices` from unique `.Location` values
- [x] 3.4 On location select: disable `InventoryName`, scope model choices to that location
- [x] 3.5 On model select (with location): filter `Design.GetInventory()` by `.Location` then `.Model`, collect `.Name` into queue

## 4. One-shot queue runtime

- [x] 4.1 Add queue state globals (`OneShotQueue`, `OneShotIndex`, `OneShotLocation`, `OneShotModel`, `OneShotPaired`)
- [x] 4.2 Implement `buildOneShotQueue(location, model)` — filter Location → Model → Name from design inventory
- [x] 4.3 Implement `rebuildOneShotQueue()` — called on location or model change; clears Paired list, populates To Be Paired (names only), sets Next Up
- [x] 4.4 Implement `updateOneShotLists()` — sync `OneShotToBePaired.Choices` and `OneShotPaired.Choices`
- [x] 4.5 Implement `advanceOneShot()` — move name to Paired, update lists, set Next Up to next item, disarm PairWithID
- [x] 4.6 Wire `InventoryLocation` and `InventoryModel` event handlers to trigger `rebuildOneShotQueue()`

## 5. Integrate with existing ID pairing

- [x] 5.1 `PairWithID.EventHandler`: set `InventoryName` to Next Up item, call `PairingMode(true)` and `listenForIDMode`
- [x] 5.2 Disable `PairWithID` when To Be Paired list is empty
- [x] 5.3 Modify `setPeripheral` success: if one-shot active, call `advanceOneShot()`
- [x] 5.4 On failure: keep current item in Next Up, show error in status log
- [x] 5.5 Update `buildDirectionsString()` for Pair by ID page (caution always visible, one-shot steps)

## 6. Documentation and build

- [x] 6.1 Update `README.md` with Pair by ID tab, location/model filter, one-shot workflow
- [x] 6.2 Run Compile QSD Plugin task to regenerate `FastDeploy.qplug`
- [ ] 6.3 Manual test: select location + model, verify To Be Paired names only, pair via one-shot, verify Paired list and Next Up advance
