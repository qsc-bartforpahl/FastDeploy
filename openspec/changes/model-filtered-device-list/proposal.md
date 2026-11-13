# Model-filtered device list

## Why

Fast Deploy's device-detail row count is currently capped at 100. Raising it
without filtering would create more controls and schedule status XML reads for
more devices, even when an operator is only working with one device type.
Large installations need access to a useful number of devices of a selected
model without querying details for every discovered peripheral.

## What Changes

- Add a model/type filter to the Network Device List, populated from the
  discovered peripherals' `part_number`.
- Keep the complete Core discovery result as the source for filter choices and
  device counts. Changing the filter reuses this cached result; only the
  explicit Refresh action starts a new Core discovery request.
- Limit the rendered/detail-enriched list to at most 150 devices matching the
  selected model. Retain the Device Count property as the desired row count,
  raise its maximum to 150, and display no more than the configured number of
  matching devices.
- Show the number of matching and displayed devices, and warn when the
  matching model has more than 150 discovered devices.
- Request status XML only for displayed devices. Route requests through the
  existing scheduler, retaining the maximum of four peripheral requests in
  flight.
- Cancel queued detail work when the selected model changes and ignore stale
  responses so data from one model cannot populate another model's rows.

## Capabilities

- `model-filtered-device-list`: Filter the device-detail view using cached
  discovery metadata and bound detail reads to displayed rows.

## Impact

- Affected code: Network Device List controls and layout, device discovery and
  detail-row population, request-queue cancellation, and tests.
- Pairing candidate lists and the Main UI location/model/name workflow are not
  changed by this proposal.
- Core discovery remains an all-device metadata request. The model filter
  reduces per-peripheral status reads, not the Core discovery response size.
- The 150-device threshold is a presentation/detail limit. All discovered
  devices remain in the cached discovery model for pairing and counts.

## Decisions

- A model selection change MUST NOT trigger another Core discovery request.
- A model selection change MAY issue status requests for the newly displayed
  matches, but only through the bounded scheduler and only up to the displayed
  row count.
- When matches exceed 150, show the first 150 devices in deterministic,
  case-insensitive name order and display a clear truncation warning.
- Preserve the configured Device Count row preference, capped at 150, rather
  than creating 150 controls unconditionally.
