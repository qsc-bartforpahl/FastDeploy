# Design: Scalable location-based pairing

## Current behavior

1. `getDevices()` requests the Core's
   `/debug/remote_support/network_debug/discovered_devices` endpoint.
2. `parseDevices()` records each non-Core device's name, IP, and part number,
   then calls `downloadFromPeripherals()` for every device.
3. `downloadFromPeripherals()` requests
   `/cgi-bin/status_xml`, parses `<id_mode>` and other status fields, and fills
   device-detail controls.
4. Selecting an inventory name builds the peripheral choices from
   `tabModeltoName`, which is keyed by model only.
5. ID pairing starts a five-second timer. Each tick starts one
   `/cgi-bin/status_xml` request for every discovered device of the selected
   model. Enabling ID pairing also sends an ID-off request to each populated
   device-detail row.
6. `updateInventory()` runs every five seconds and calls `getDevices()` when
   an inventory status changes, which can repeat the discovery and
   per-peripheral status-read burst.

The ID-on/off value is read from the peripheral's `<id_mode>` element in
`/cgi-bin/status_xml`. ID mode is turned off using
`/cgi-bin/id_mode?mode=off`; this is a separate command request. It is not
currently read from the Core discovery response.

The discovery loop uses the full discovery response to index fixed-size device
control arrays. The device-detail display count is configurable and capped at
100, so the discovery data model and selector choices must not depend on those
arrays when a Core reports more devices than the display limit.

## Proposed design

### Inventory location metadata

Use the `Location` field returned by `Design.GetInventory()` for Designer
inventory entries (the items being assigned). Newly discovered peripherals
have not been adopted yet, so they do not have a location to use for filtering.
Do not fetch location from each peripheral or infer it from its name.
The field is documented in the
[Q-SYS Design Lua API](https://help.qsys.com/Content/Control_Scripting/Using_Lua_in_Q-Sys/Design.htm).

Use inventory location to build the location selector and filter the available
inventory models and names. Preserve and normalize the inventory location for
matching and sorting. Missing/blank inventory locations appear under
`Unassigned`.

### Cascading selectors

- Location choices contain locations represented in the current inventory and
  sort case-insensitively with a stable tie-breaker.
- Changing location clears model and name selections and their downstream
  choices.
- Model choices are limited to the selected location and sorted consistently.
- Changing model clears the name selection and rebuilds names for that
  location/model pair.
- Names are limited to inventory entries for the selected location/model and
  sorted consistently.
- `Prev Device` and `Next Device` navigate that filtered, sorted inventory-name
  list one name at a time and update the inventory-name dropdown to the exact
  selected entry.
- The navigation cursor follows the current inventory-name selection. If a
  successful pairing clears that selection, retain the last successfully
  paired inventory name as the cursor so `Next Device` proceeds to its
  successor and `Prev Device` can return to its predecessor.
- Clear the green pairing-success indicator when navigation selects a
  different name; only show success for the name whose pairing succeeded.
- Changing location or model resets the cursor to the current valid selection
  in the new list, or to no selection if there is none. From no selection,
  Next starts at the first name and Prev starts at the last.
- Ignore empty placeholder choices. If the filtered list is empty, both
  buttons are disabled. At either end of a non-empty list, the corresponding
  button is disabled; navigation does not wrap around. Navigation never
  triggers assignment or device HTTP requests by itself.
- Peripheral candidates for manual assignment are limited to online devices
  matching the selected model. They are not filtered by location.
- ID pairing retains the selected location/model/name and only scans eligible
  online candidates for the selected model. Location affects which inventory
  item is selected, not which unadopted peripherals are polled.

### Discovery and request scheduling

- Treat the Core discovery response as the source for online-device identity,
  model, and address; do not make status requests merely to populate selector
  choices.
- Coalesce automatic refresh triggers so a burst of inventory status changes
  does not start overlapping discovery cycles.
- Keep optional status enrichment separate from discovery and limit it to the
  device-detail rows that can actually be displayed or to a user-requested
  operation.
- Maintain a complete data model for all discovered peripherals independently
  of the configured device-detail display count.
- Schedule ID status checks through a queue with a fixed maximum number of
  concurrent requests. Do not start a new poll cycle that duplicates
  outstanding requests.
- The polling queue includes only devices matching the active model. Since
  peripherals have no location before adoption, location does not filter the
  queue. Stop and invalidate pending work when pairing mode or its selection
  changes, or when an ID-on device is found.
- Scope ID-off commands to the active model's candidate set and schedule them
  through the same bounded-request mechanism. Do not send ID-off to unrelated
  models merely because they appear in the detail list. Report failures and do
  not resume polling as though all ID-off operations succeeded.
- Keep manual assignment network configuration requests unchanged.

The concurrency limit is four peripheral requests, independent of the number of
discovered devices. ID polling remains on a five-second timer but does not
start another cycle while the current queue is in flight. The initial
validation target is a 750-peripheral discovery fixture: selector population
must not issue 750 status requests, and active ID polling must never exceed
four in-flight requests.

## Alternatives considered

- **Sort device names by location-like text:** rejected because location is not
  currently represented in the plugin's data and name parsing is ambiguous.
- **Fetch status XML for all devices and sort afterward:** rejected because it
  preserves O(N) status requests during normal discovery.
- **Filter online peripherals by the selected location:** rejected because
  unadopted peripherals have no location. Location filters planned inventory
  items; model filters online peripheral candidates and ID polling.

## Risks

- Since location is not available on unadopted peripherals, a selected
  inventory location does not by itself reduce the online-device candidate
  set. Model filtering and bounded polling control the peripheral requests.
- Validate the fixed concurrency limit with a representative live Core before
  relying on it in large installations.
- Reducing automatic status reads means the device-detail table may not have
  fresh status values until enrichment is requested or scheduled.
- Bounded ID polling trades request load for detection latency; validate the
  selected cadence with representative device counts.
