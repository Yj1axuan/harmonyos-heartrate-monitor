# HeartRate HarmonyOS

HarmonyOS native scaffold for the HeartRateMonitor project.

## Environment

- DevEco Studio 6.0.0
- HarmonyOS SDK 6.0.0 / API 20
- ArkTS + ArkUI Stage model
- Hvigor 6.0.6

## Current scope

- EntryAbility and a runnable ArkUI shell
- Monitoring, history, and settings tabs
- Standard BLE Heart Rate Measurement (`0x2A37`) parser
- Ports for BLE, persistence, and background monitoring
- Repository boundary for later platform implementations

## Architecture

```text
pages -> application controller -> domain repository
                                  |-> BLE port
                                  |-> store port
                                  `-> monitoring task port
```

Platform adapters are intentionally not implemented in this first scaffold. The first technical milestone is a real-device BLE proof of concept with background monitoring.

## Build

Open this directory in DevEco Studio, allow project sync, select an API 20 phone target, and run the `entry` module.

