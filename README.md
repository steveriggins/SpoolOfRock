# SpoolOfRock

SpoolOfRock is an iOS app for tracking 3D printer filament spools, with NFC support for quick lookup and assignment.

## What It Does

- Track spool metadata:
  - Manufacturer
  - Filament type
  - Color
  - Original weight
  - Current weight
- Calculate remaining percentage for each spool.
- Scan NFC tags to jump directly to the spool details.
- Assign or reassign NFC tags to spools.
- Handle NFC tag conflicts:
  - If a tag is already assigned to another spool, the app prompts for confirmation.
  - On confirmation, the old spool tag association is removed and the tag is reassigned.

## Current UX

- Main screen has two large primary actions:
  - **Scan Spool**
  - **Add Spool**
- Scanning is explicit and user-triggered (no automatic background scanner popups).
- Scan outcomes are shown in a dedicated result screen.

## Tech Stack

- SwiftUI
- SwiftData
- CoreNFC
- Tuist project structure

## Project Structure (high level)

- `SpoolOfRock/Sources/Models` - domain models
- `SpoolOfRock/Sources/DataLayer` - repository abstractions and implementations
- `SpoolOfRock/Sources/Services` - NFC services and manager
- `SpoolOfRock/Sources/ViewModels` - view model logic
- `SpoolOfRock/Sources/Views` - SwiftUI views

## NFC Flow

### Scan

1. User taps **Scan Spool**.
2. App reads tag data.
3. If spool is found, app navigates to that spool.
4. If no spool matches, app shows a scan result screen with next actions.

### Assign/Reassign

1. User taps **Assign NFC Tag** / **Reassign NFC Tag** in spool details.
2. App scans the tag first to detect potential ownership conflicts.
3. If already owned by another spool, app shows confirmation.
4. On confirm, previous spool mapping is removed, then tag is written to current spool.

## Requirements

- Xcode 15+
- iOS device with NFC support for real NFC features
- iOS Simulator works for non-NFC features (uses mock NFC service)

## Build & Run

1. Open the project in Xcode.
2. Select the `SpoolOfRock` scheme.
3. Build and run.

## Tests

- Unit tests are in `SpoolOfRock/Tests`.
- Run from Xcode Test action.

## Notes

- NFC writing stores the spool UUID in NDEF text payload.
- App includes compatibility lookup for existing saved tag identifiers.

## Roadmap Ideas

- Add onboarding for first-time NFC usage.
- Add import/export for spool library.
- Add analytics/history for filament consumption.
- Add more robust conflict and duplicate detection UX.

## License

No license has been specified yet.
