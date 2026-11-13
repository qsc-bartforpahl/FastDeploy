# Design: Model-filtered device list

## Resulting behavior

- The Core discovery endpoint returns device name, IP, and `part_number`;
  successful results populate the full discovery catalog used by pairing and
  the Network Device List filter.
- The Network Device List filter has `All Models` and sorted discovered model
  choices. Filter changes reuse the catalog and request detail XML for the
  displayed rows only.
- The `Device Count` property controls detail-row controls and is capped at
  150, with its default remaining 50.
- The detail list is sorted by name and displays at most the configured row
  count and 150 matches. The summary reports matches versus displayed rows and
  warns when more than 150 devices match.
- Detail reads use the shared peripheral request queue, with at most four
  requests in flight. Filter and discovery generations prevent late responses
  from writing into rows for a different view. Failed Core discovery preserves
  the last successful catalog and visible list.

## Proposed design

### Cached discovery and model filter

Maintain a complete discovery catalog independent of the currently displayed
rows. Each record contains the fields provided by Core discovery needed for
the list, including name, LAN A IP, and model (`part_number`). Build a sorted
model filter from that catalog, with an `All Models` choice.

The Refresh action initiates Core discovery and replaces the catalog after a
successful response. Changing the model filter does not call Core discovery.
Instead, it selects records from the current catalog and renders the filtered
rows. Discovery failure remains visible through the existing error reporting
and does not become a successful empty catalog.

### Row and threshold behavior

The `Device Count` property remains the operator's requested number of detail
rows and is raised from a maximum of 100 to a maximum of 150. Its default does
not change. The number of rendered devices is:

`min(configured Device Count, 150, matching discovered-device count)`

For `All Models`, the matches are all discovered peripherals. For a selected
model, matches are only peripherals whose discovery `part_number` matches that
model. Sort matched device names case-insensitively with a stable tie-breaker
before applying the row limit, so the same devices are shown for a given
discovery result.

Show both the total match count and displayed count. If the total match count
exceeds 150, show a clear warning that the list is capped at 150 and that
additional matching devices remain discovered but are not shown in the detail
table. If the configured row count is below the available matches, the count
indicator also makes clear that only the configured number is displayed.

### Detail status request scheduling

Only rendered rows receive automatic status XML enrichment. A filter change
invalidates the prior detail-view generation, cancels queued `device-detail`
requests belonging to the previous view, clears stale row values, and queues
status reads for the new rendered rows. Requests continue through the existing
four-request scheduler. Responses carry the view/discovery generation and
update a row only if it still represents the same device in the active view.
Already in-flight requests may complete but must not write stale data into a
new filter's rows.

Do not fetch status XML for hidden rows or undisplayed matches. When a model
filter changes, refresh the displayed rows from the matching devices using the
existing bounded scheduler. ID-mode polling remains separate and follows its
existing selected-pairing-model behavior and request limit.

## Alternatives considered

- **Re-discover from the Core every time the filter changes:** rejected because
  the model choices and device metadata are already available from the last
  discovery, and extra Core calls provide no benefit for local filtering.
- **Raise the global row limit to 500:** rejected because it expands control
  count and total status reads without helping an operator focus on a device
  type.
- **Status-read every matching device, even when not displayed:** rejected
  because it needlessly increases HTTP traffic and does not provide additional
  visible detail.
- **Silently truncate over-limit models:** rejected because an operator could
  mistake an incomplete table for the full model population.

## Risks

- The Core discovery endpoint still returns the complete discovered-device
  list; this proposal limits per-device detail reads, not discovery payload
  size.
- A deterministic name-based cap makes only the first 150 visible when one
  model has more than 150 devices. The warning must be conspicuous so operators
  know the table is incomplete.
- Changing filters while detail requests are in flight requires generation
  checks to prevent stale asynchronous results from corrupting the visible
  rows.
- Validate the row/control count and layout in Q-SYS Designer with 150
  configured rows and representative large discovery results.
