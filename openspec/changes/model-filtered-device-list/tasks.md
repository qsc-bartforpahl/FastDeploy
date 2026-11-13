# Tasks: Model-filtered device list

## 1. Model filter and catalog

- [x] Add a Network Device List model filter populated from the complete
      successful Core discovery catalog, including an `All Models` choice.
- [x] Keep the discovery catalog independent of the filtered and displayed
      rows; filter changes must not request Core rediscovery.
- [x] Preserve the last successful catalog when a refresh fails and report
      the failure explicitly.

## 2. Bounded detail rows

- [x] Raise the Device Count property maximum from 100 to 150 without changing
      its default.
- [x] Filter discovered devices by model, sort names deterministically, and
      render at most the configured row count and 150 devices.
- [x] Display matching and displayed counts, and warn when more than 150
      devices match.
- [x] Keep all discovered devices available to pairing independent of which
      devices are shown in detail rows.

## 3. Detail request lifecycle

- [x] Queue status XML reads only for devices displayed in the current filter.
- [x] Preserve the maximum of four concurrent per-peripheral requests.
- [x] Cancel queued old-view detail requests and reject stale responses after a
      filter or discovery generation changes.
- [x] Keep ID-mode polling behavior and pairing selectors unchanged.

## 4. Verification

- [x] Add tests for model choices, `All Models`, cached filtering, and no Core
      discovery request on model changes.
- [x] Test configured row counts, the 150-device cap, sorted deterministic
      selection, counts, and the over-limit warning.
- [x] Test that only displayed rows receive status reads and concurrency never
      exceeds four.
- [x] Test canceled queued requests and stale in-flight detail responses after
      filter/discovery changes.
- [ ] Validate the 150-row layout and control count in Q-SYS Designer.
