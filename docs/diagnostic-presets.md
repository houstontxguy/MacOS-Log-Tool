# Diagnostic Presets

The app includes 12 curated diagnostic presets for common macOS troubleshooting scenarios. Each preset defines a set of subsystems, processes, and keywords to filter relevant log entries.

## Accessing Presets

Presets appear in the sidebar under **Quick Diagnostics**. Click any preset to automatically fetch and analyze relevant logs.

## Preset Reference

### Wi-Fi Issues
- **Icon:** wifi.exclamationmark
- **Subsystems:** `com.apple.WiFiManager`, `com.apple.wifi`
- **Processes:** `airportd`
- **Use when:** Wi-Fi disconnects, slow speeds, connection failures, authentication issues

### Bluetooth
- **Icon:** wave.3.right
- **Subsystems:** `com.apple.bluetooth`
- **Processes:** `blued`, `bluetoothd`
- **Use when:** Bluetooth device pairing failures, audio dropouts, HID disconnects

### Sleep / Wake
- **Icon:** moon.zzz
- **Processes:** `powerd`, `kernel`
- **Keywords:** "Wake reason"
- **Use when:** Mac won't sleep, unexpected wake events, sleep/wake crashes, power issues

### Login / Auth
- **Icon:** person.badge.key
- **Subsystems:** `com.apple.login`, `com.apple.loginwindow.logging`
- **Processes:** `loginwindow`, `opendirectoryd`, `authd`, `tccd`
- **Use when:** Login failures, authentication errors, permission denials, TCC issues

### Disk / Storage
- **Icon:** externaldrive
- **Subsystems:** `com.apple.StorageKit`
- **Processes:** `fsck_apfs`, `diskutil`
- **Use when:** Disk errors, APFS issues, mount failures, storage warnings

### Network
- **Icon:** network
- **Subsystems:** `com.apple.network`
- **Processes:** `mDNSResponder`
- **Use when:** DNS resolution failures, network stack errors, connectivity issues

### WindowServer / Display
- **Icon:** display
- **Processes:** `WindowServer`
- **Use when:** Display glitches, rendering issues, window management problems, GPU errors

### Time Machine
- **Icon:** clock.arrow.circlepath
- **Subsystems:** `com.apple.TimeMachine`
- **Use when:** Backup failures, Time Machine errors, snapshot issues

### Spotlight
- **Icon:** magnifyingglass
- **Processes:** `mds`, `mds_stores`, `mdworker_shared`
- **Use when:** Search not working, indexing issues, high CPU from Spotlight

### Software Update
- **Icon:** arrow.down.app
- **Subsystems:** `com.apple.SoftwareUpdate`
- **Processes:** `softwareupdated`
- **Use when:** Update failures, download errors, installation problems

### Security
- **Icon:** lock.shield
- **Subsystems:** `com.apple.securityd`
- **Processes:** `sshd`, `tccd`, `screensharingd`
- **Use when:** Security policy violations, SSH issues, screen sharing problems

### Kernel / System
- **Icon:** cpu
- **Processes:** `kernel_task`, `launchd`
- **Default Level:** Fault
- **Use when:** Kernel panics, system-level faults, launchd issues, boot problems

## How Presets Work

Each preset builds a `LogFilter` using the `predicate` field to construct compound OR queries:

```
subsystem == "com.apple.bluetooth" OR process == "blued" OR process == "bluetoothd"
```

This is passed directly to the macOS `log` command's `--predicate` flag, so filtering happens at the system level for maximum performance.

## Customization

Presets are defined in `Sources/LogToolApp/Models/DiagnosticPreset.swift`. Each preset specifies:

- `id` — Unique identifier
- `name` — Display name
- `icon` — SF Symbol name
- `subsystems` — Array of subsystem strings to match
- `processes` — Array of process names to match
- `keywords` — Array of message keywords to search for
- `defaultLevel` — Optional minimum log level filter

The `buildFilter(lastMinutes:)` method constructs a `LogFilter` with the appropriate predicate and time range.
