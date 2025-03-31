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

The plugin contains three pages:

1. **Main UI**: Primary interface for device pairing and assignment
2. **Network Device List**: Displays all discovered devices on the network
3. **Extra Stuff**: Additional network configuration and utility functions

## Properties

- **Debug Print**: Controls debug output level
- **Device Count**: Sets the number of devices that can be displayed in the device list (range: 1-100, default: 15)

## Usage

1. Drag the plugin into your design
2. Use the "Get" button to discover devices on the network
3. Select an inventory model and name
4. Select a device to assign the inventory item to
5. Optionally configure IP settings if using static IP
6. Press "Assign" to complete the pairing

### ID Mode Pairing

For devices that support ID mode:

1. Enable "Pair With ID" mode
2. Select an inventory model and name
3. Press the ID button on the physical device you want to pair
4. The system will automatically associate the pressed device with the selected inventory item

## Requirements

- Q-SYS Designer 9.0 or higher
- Q-SYS Core devices
- Q-SYS compatible peripheral devices

## Support

For support or feature requests, please contact the author.