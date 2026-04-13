# Kalendar

A lightweight macOS menu bar calendar app. Click the calendar icon in your menu bar to view a full month calendar.

## Features

- **Menu bar icon** with current day number
- **Full month calendar** grid (Monday-start weeks)
- **Today highlighted** with accent color
- **Month navigation** with arrow buttons
- **Quick "Today" button** to jump back to current month
- **Starts at login** automatically
- **No dock icon** — runs purely in the menu bar

## Install

1. Download `Kalendar.dmg` from [Releases](https://github.com/champ3oy/kalendar/releases)
2. Open the DMG and drag **Kalendar** to Applications
3. Launch Kalendar — it appears in your menu bar

## Build from source

```bash
xcodebuild -project Kalender.xcodeproj -scheme Kalendar -configuration Release build
```

## Requirements

- macOS 13.0+
