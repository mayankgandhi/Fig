# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a SwiftUI macOS/iOS application using SwiftData for persistence. The app uses the modern SwiftUI app lifecycle with `@main` and SwiftData's `ModelContainer` for data management.

## Architecture

- **App Entry Point**: `fig/figApp.swift` - Defines the main app structure and sets up the SwiftData `ModelContainer` with the `Item` model
- **Data Models**: `fig/Item.swift` - SwiftData models using the `@Model` macro
- **Views**: `fig/ContentView.swift` - SwiftUI views that use `@Query` to fetch SwiftData objects and `@Environment(\.modelContext)` to access the model context
- **Tests**:
  - `figTests/` - Unit tests
  - `figUITests/` - UI tests

## Common Commands

Build and run the app:
```bash
xcodebuild -project fig.xcodeproj -scheme fig build
```

Run tests:
```bash
xcodebuild test -project fig.xcodeproj -scheme fig
```

Alternatively, open the project in Xcode:
```bash
open fig.xcodeproj
```

## SwiftData Usage

The app uses SwiftData for persistence:
- Models are defined with the `@Model` macro
- The `ModelContainer` is configured in `figApp.swift` with persistent storage (not in-memory)
- Views access data using `@Query` for fetching and `@Environment(\.modelContext)` for mutations
- The schema is registered in the `ModelContainer` initialization
