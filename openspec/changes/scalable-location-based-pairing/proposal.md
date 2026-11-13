# Scalable location-based pairing

## Why

Fast Deploy currently offers a model-filtered inventory workflow, but it has no
location selector. In a large design, finding the right inventory item and
peripheral becomes difficult. Device discovery also requests `status_xml` from
every discovered peripheral, and ID pairing polls every online peripheral of
the selected model every five seconds. These per-device requests can create
unnecessary load on the Core and peripherals as a system grows.

## What Changes

- Add a cascading pairing workflow: select a location, then an inventory model,
  then an inventory name.
- Add `Prev Device` and `Next Device` buttons to step through the sorted
  inventory names for the selected location and model, keeping the inventory
  name selection synchronized.
- Use location only to filter the Designer inventory items, since newly
  discovered peripherals have not yet been adopted or assigned a location.
- Filter online peripheral candidates by the selected model, not location.
- Sort location, model, inventory-name, and peripheral choices consistently
  and case-insensitively.
- Separate core discovery metadata from optional per-peripheral status reads so
  discovery and selector population do not require one HTTP request per
  peripheral.
- Scope ID-mode detection and ID-off commands to the selected model, and
  schedule requests with a bounded number in flight.
- Make discovery and pairing safe when the Core reports substantially more
  devices than the configured device-detail display count.

## Capabilities

- `location-based-pairing`: Location-aware cascading selection and candidate
  filtering.
- `scalable-device-discovery`: Bounded peripheral HTTP traffic and support for
  large discovered-device sets.

## Open Questions

- Validate the chosen four-request concurrency limit on a representative Core
  and deployment. The limit is fixed and covered by automated tests; live
  hardware validation is still required.

## Impact

- Affected code: pairing selectors and event handlers, inventory/discovery
  metadata handling, ID-mode polling, and tests.
- No HTTP API changes are proposed. The implementation must validate the
  inventory location metadata source before depending on it.
- Location selection narrows inventory model/name choices; the selected model
  narrows online peripheral candidates and ID-mode requests.
- Prev/Next changes only the inventory-name selection; it does not automatically
  assign or send requests to a peripheral.
- Inventory items without a location appear under `Unassigned`.
