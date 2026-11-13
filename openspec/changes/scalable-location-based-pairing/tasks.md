# Tasks: Scalable location-based pairing

## 1. Validate location metadata

- [x] Confirm `Design.GetInventory()` exposes `Location` on inventory items;
      do not require location metadata on unadopted peripherals.
- [x] Normalize missing/blank inventory location to `Unassigned`.

## 2. Implement cascading selectors

- [x] Extend inventory records with validated location metadata; do not attach
      location to unadopted discovered peripherals.
- [x] Build sorted location, model, and name choices with cascading filtering
      and downstream selection clearing.
- [x] Add Prev Device and Next Device controls that traverse the filtered name
      list, retain the last successful name as the cursor when needed, and
      synchronize the inventory-name dropdown.
- [x] Filter manual assignment and ID-mode candidates by selected model;
      location filters inventory choices only.
- [x] Preserve pairing availability for inventory items with missing location
      through the agreed fallback (for example, `Unassigned`).

## 3. Scale discovery and ID polling

- [x] Separate the complete discovered-device data model from the bounded
      device-detail control arrays.
- [x] Remove all-device status XML enrichment from the selector-population
      path; retain bounded optional detail enrichment.
- [x] Coalesce automatic rediscovery triggers so inventory status changes
      cannot start overlapping discovery cycles.
- [x] Add a bounded request scheduler for ID polling and ID-off commands,
      preventing overlapping duplicate polls.
- [x] Cancel or invalidate pending work on selection changes, mode exit, and
      successful detection; preserve explicit error behavior.

## 4. Verify behavior and load

- [x] Add tests for cascading choices, sorting, location/model filtering,
      `Unassigned`, and stale responses after selection changes.
- [x] Add tests for Prev/Next ordering, dropdown synchronization, successful
      pairing cursor retention, empty lists, boundaries, and parent-selection
      changes; verify navigation does not issue device requests or assignments.
- [x] Add tests for discovery beyond the configured device-detail count,
      including 750 discovered peripherals.
- [x] Assert selector population makes no per-device status XML requests.
- [x] Assert ID polling and ID-off work stay within the chosen concurrency
      limit and target only the active model candidates.
- [x] Run `lua tests/run.lua` and update user documentation for the new
      selection workflow and ID polling behavior.
