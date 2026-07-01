# Fast Deploy Plugin

Version: 1.0.0  
Author: Bartholomew Forpahl

## Description

The Fast Deploy plugin is designed to streamline the process of deploying Q-SYS peripherals in a system. Key features include:

- **Streamlined Pairing**: Quick pairing of inventory items to peripherals on the network via the core
- **Remote Management**: Designed to work seamlessly with Q-SYS Reflect Enterprise Manager
- **UCI Support**: Allows pairing of devices to a User Control Interface (UCI) without requiring a laptop in the room
- **Flexible Deployment**: Ideal for assigning cold storage devices to specific rooms or rapidly deploying devices across a system

## Pages

The plugin contains five pages:

1. **Main UI**: Primary interface for standard device pairing and assignment (select peripheral, Assign)
2. **Pair by ID**: One-shot ID-mode pairing with location/model filter and queue workflow
3. **Leaderboards**: Arcade-style pairing speed stats, device-type rankings, and time saved vs manual benchmark
4. **Network Device List**: Displays all discovered devices on the network
5. **Extra Stuff**: Additional network configuration and utility functions

## Properties

- **Debug Print**: Controls debug output level
- **Device Count**: Sets the number of devices that can be displayed in the device list (range: 1-100, default: 15)

## Usage

### Standard pairing (Main UI)

1. Drag the plugin into your design
2. Use the "Refresh" button to discover devices on the network
3. Select an inventory model and name
4. Select a device to assign the inventory item to
5. Optionally configure IP settings if using static IP
6. Press "Assign" to complete the pairing

### Pair by ID — one-shot queue (Pair by ID tab)

For sequential room deployments using ID mode:

1. Open the **Pair by ID** tab
2. Select **Location** (from design inventory `Location` field)
3. Select **Model** (scoped to that location)
4. The **To Be Paired** list populates with matching inventory names; **Next Up** shows the current target
5. Press **Pair With ID** when ready
6. Press the physical ID button on the device
7. On success, the device moves to **Paired** and **Next Up** advances automatically
8. Repeat steps 5–7 for each remaining device

Inventory is filtered via `Design.GetInventory()` using `.Location`, then `.Model`, then `.Name`. List boxes show names only because location and model are already selected.

### Leaderboards — pairing analytics

The **Leaderboards** tab tracks how fast ID-mode pairing runs during the current session:

1. Timing starts when **Pair With ID** is pressed and stops on success or failure (`Timer.Now()`)
2. View **total devices**, **total time**, and **average time per device**
3. See **TOP 10 FASTEST** and **TOP 10 SLOWEST** individual devices
4. See **BY DEVICE TYPE** rankings — which models pair fastest and slowest on average
5. **TIME SAVED** compares your session to a **3 minute per device** manual pairing benchmark  
   Example: 100 devices in 1200 s (20 min) vs 18000 s benchmark (300 min) = **280 min saved (4 hr 40 min)**
6. Press **RESET STATS** to clear the session and start fresh
7. Screenshot the Leaderboards tab to share rankings on the Q-SYS community page

Analytics apply to ID pairing on both the **Pair by ID** and **Main UI** tabs. Standard Assign (non-ID) pairing is not timed.

## Requirements

- Q-SYS Designer 9.0 or higher
- Q-SYS Core devices
- Q-SYS compatible peripheral devices

## Support

For support or feature requests, please contact the author.
