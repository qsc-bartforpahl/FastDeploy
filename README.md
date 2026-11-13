# Fast Deploy Plugin

Version: 1.5.3
Author: Bartholomew Forpahl

## Description

The Fast Deploy plugin is designed to streamline the process of deploying Q-SYS peripherals in a system. Key features include:

- **Streamlined Pairing**: Quick pairing of inventory items to peripherals on the network via the core
- **Remote Management**: Designed to work seamlessly with Q-SYS Reflect Enterprise Manager
- **UCI Support**: Allows pairing of devices to a User Control Interface (UCI) without requiring a laptop in the room
- **Flexible Deployment**: Ideal for assigning cold storage devices to specific rooms or rapidly deploying devices across a system

## Pages

The plugin contains three pages:

1. **Main UI**: Primary interface for device pairing and assignment
2. **Network Device List**: Displays all discovered devices on the network
3. **Extra Stuff**: Additional network configuration and utility functions

## Properties

- **Debug Print**: Controls debug output level
- **Device Count**: Sets the number of device detail rows (range: 1-150, default: 50)

On the **Network Device List** page, use the model filter to focus the detail
table on one peripheral model or select **All Models**. Changing the filter
uses the latest discovery results; press **Refresh** to query the Core again.
The table displays up to the configured Device Count and 150 devices, sorted by
name. It reports the matching and displayed counts and warns when more than
150 devices match. All discovered devices remain available to the pairing
workflow.

Status XML is requested only for displayed rows, with at most four peripheral
requests in flight. Changing the filter cancels queued detail reads for the
previous view, and late responses cannot overwrite the currently displayed
devices.

## Usage

1. Drag the plugin into your design
2. Use the "Get" button to discover devices on the network
3. Select an inventory location, model, and name
4. Use **Prev Device** / **Next Device** to step through the sorted inventory
   names without scrolling the dropdown
5. Select an online peripheral and assign the inventory item
6. Optionally configure IP settings if using static IP
7. Press "Assign" to complete the pairing

The location selector filters Designer inventory items. Unadopted network
peripherals do not have a Designer location yet, so the selected model filters
the online peripheral candidates and ID-mode scan. Device discovery uses the
Core's discovered-device list; per-device status reads are limited to the
configured device-detail rows. ID-mode status requests are queued with at most
four peripheral requests in flight.

### ID Mode Pairing

For devices that support ID mode:

1. Enable "Pair With ID" mode
2. Select an inventory model and name
3. Press the ID button on the physical device you want to pair
4. The system will automatically associate the pressed device with the selected inventory item

Enable **Keep Pair by ID Enabled** before pairing to pair several devices in succession.
After each successful pairing, Pair With ID remains enabled and the inventory model
and name remain selected. The plugin sends ID-off to discovered devices of that
model and waits for those commands to succeed before listening again. Choose the
next Inventory Name, then press ID on the next physical device. Devices of other
models are not sent ID-off during this step. The Inventory Name field turns green
after a successful pairing; changing the name or model clears the color until the next
successful pairing. If an ID-off command fails, the plugin
reports the error and pauses listening; resolve the error and select the name again
to retry pairing. Leave the option off for the existing one-pair-at-a-time behavior.

## Tests

Run `lua tests/run.lua` from the repository root. The tests mock the Q-SYS runtime
and HTTP callbacks to cover single and repeated ID pairing, selection changes,
ID-off failures, and network-settings compatibility. They do not contact devices.
Use `lua tests/run.lua FastDeployPlugin.qplug` to test the compiled plugin instead
of the runtime source.

## Requirements

- Q-SYS Designer 9.0 or higher
- Q-SYS Core devices
- Q-SYS compatible peripheral devices

## Support

For support or feature requests, please contact the author.