# HeartRate HarmonyOS

HeartRate is a native HarmonyOS ArkTS application for Bluetooth heart-rate monitoring.

## Features

- Bluetooth device discovery and connection
- Standard BLE Heart Rate Measurement (`0x2A37`) parsing
- Real-time heart-rate dashboard and trend chart
- Full-screen monitoring mode
- Monitoring history and favorite devices
- Theme, alert, background monitoring, and display settings

## Environment

- DevEco Studio 6.0.0
- HarmonyOS SDK 6.0.0 / API 20
- ArkTS + ArkUI Stage model
- Hvigor 6.0.6

The app currently uses several Bluetooth APIs that require newer HarmonyOS SDK capabilities. Build warnings are expected if `compatibleSdkVersion` stays below those API levels.

## Architecture

```text
pages
  -> ui pages
  -> application view models and use cases
  -> domain repository and ports
  -> HarmonyOS data, BLE, permission, alert, and preferences adapters
```

Key boundaries:

- `entry/src/main/ets/domain`: domain models, parser, repository contract, and ports
- `entry/src/main/ets/application`: UI state, view models, and use cases
- `entry/src/main/ets/data`: HarmonyOS platform adapters
- `entry/src/main/ets/ui`: ArkUI pages and theme
- `entry/src/main/ets/core/di`: application wiring

## Build

Open this directory in DevEco Studio, allow project sync, select the `entry` module, then build or run on a HarmonyOS phone/tablet target.

Command-line build:

```powershell
& 'C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe' 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p product=default assembleHap --analyze=normal --parallel --incremental
```

## Signing

Do not commit personal signing certificates, passwords, or local certificate paths. Keep release signing material in your local DevEco configuration or CI secrets.

## License

MIT
