# BalanceBot iOS App

iPhone companion app for the balancing robot. Displays real-time orientation data from the IMU and provides control interface.

## Features

- **Bluetooth Connection**: Scan and connect to XBee Bluetooth module
- **Live Attitude Display**: Roll, pitch, yaw in degrees with color-coded severity
- **Artificial Horizon**: Visual tilt indicator like an aircraft instrument
- **LED Control**: Toggle onboard LED for communication testing
- **Future**: Motor control joystick

## Architecture

The app uses **MVVM** (Model-View-ViewModel) architecture:

```
Models/          - Data structures (Attitude, DeviceState, Command)
Services/        - Business logic (BluetoothService, AttitudeParser)
ViewModels/      - State management (ConnectionViewModel, AttitudeViewModel)
Views/           - SwiftUI views
Components/      - Reusable UI components
```

## Requirements

- iOS 17.0+
- iPhone with Bluetooth LE
- Xcode 15+

## Setup in Xcode

1. Open Xcode
2. File → New → Project → iOS App
3. Product Name: `BalanceBot`
4. Interface: SwiftUI
5. Language: Swift
6. Delete the generated `ContentView.swift`
7. Drag all files from `ios_app/BalanceBot/` into the project
8. Ensure `Info.plist` Bluetooth permissions are included

## Bluetooth Protocol

### Receiving Data (MCU → iPhone)

Format: `R:<roll> P:<pitch> Y:<yaw>\r\n`

Example: `R:12.3 P:-4.5 Y:0.0\r\n`

### Sending Commands (iPhone → MCU)

| Command | Format | Description |
|---------|--------|-------------|
| Start streaming | `START\n` | Begin IMU telemetry (R: P: Y:). Connection is separate from initiation. |
| Stop streaming | `STOP\n` | Pause IMU telemetry; connection stays open. |
| LED Toggle | `LED\n` | Toggle onboard LED |
| Motor | `M:<throttle>,<turn>\n` | Motor control (future) |

## XBee BLE UUIDs

The app uses Nordic UART Service (NUS) UUIDs, common for XBee Bluetooth:

- Service: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`
- TX (write): `6E400002-B5A3-F393-E0A9-E50E24DCCA9E`
- RX (notify): `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`

> **Note**: These may need adjustment for your specific XBee module. Check the XBee documentation or use a BLE scanner app to find the correct UUIDs.

## Testing Without Hardware

The app will show "Searching for devices..." without the XBee module. To test the UI:

1. Use SwiftUI Previews in Xcode
2. Or mock the BluetoothService for simulator testing

## Screenshots

(Add screenshots here after running on device)
