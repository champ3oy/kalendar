# Kalendar

A lightweight macOS menu bar calendar app. Click the calendar icon in your menu bar to view a full month calendar with your events and reminders.

## Features

- **Menu bar icon** with current day number
- **Full month calendar** grid (Monday-start weeks)
- **Today highlighted** with accent color
- **Month navigation** with arrow buttons
- **Quick "Today" button** to jump back to current month
- **Calendar events** — days with events show a dot indicator; click a day to see the list
- **Reminders** — view reminders due on each day and toggle completion
- **Click to open** — click an event to open it in Apple Calendar
- **Starts at login** automatically
- **No dock icon** — runs purely in the menu bar

## Install

1. Download `Kalendar.dmg` from [Releases](https://github.com/champ3oy/kalendar/releases)
2. Open the DMG and drag **Kalendar** to Applications
3. Launch Kalendar — it appears in your menu bar
4. Grant calendar and reminders access when prompted

## Build from source

```bash
xcodebuild -project Kalender.xcodeproj -scheme Kalendar -configuration Release build
```

## Requirements

- macOS 13.0+
