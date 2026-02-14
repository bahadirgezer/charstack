# Charflow

A minimal daily task manager for iOS. Four regions, the 1-3-5 rule, and nothing else.

[![iOS 26+](https://img.shields.io/badge/iOS-26.0%2B-blue)](https://developer.apple.com/ios/)
[![Swift 6](https://img.shields.io/badge/Swift-6.0-orange)](https://www.swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-100%25-blueviolet)](https://developer.apple.com/swiftui/)
[![License: MIT](https://img.shields.io/badge/License-MIT-lightgrey)](LICENSE)

---

## The idea

Most task apps become infinite lists. Charflow doesn't let that happen.

Your day is split into **Morning**, **Afternoon**, **Evening**, and **Backlog**. Each active region follows the **1-3-5 rule**: 1 must-do, up to 3 complementary tasks, up to 5 misc. That's it. Anything unfinished rolls to Backlog at the end of the day.

> "Char" (چهار) = Persian for **4**. Four regions, one focused flow.

## Tech

SwiftUI · SwiftData · MVVM · iOS 26+ · No external dependencies

## Setup

```bash
git clone https://github.com/bahadirgezer/charstack.git
open charstack/Charstack.xcodeproj
# Cmd+R to build and run
```

Requires Xcode 16+ and macOS 14+.

## Versioning

- `VERSION` is the source of truth for semantic app version (`MARKETING_VERSION` / `CFBundleShortVersionString`).
- `CURRENT_PROJECT_VERSION` (`CFBundleVersion`) should be a monotonically increasing build number.
- Sync project settings from `VERSION`:

```bash
./scripts/sync-xcode-version.sh
```

- Sync version and set a local build number:

```bash
./scripts/sync-xcode-version.sh --build-number 42
```

## Status

MVP in progress. Not yet on the App Store.

## Docs

- [Project Brief](docs/PROJECT_BRIEF.md) — what and why
- [Requirements](docs/REQUIREMENTS.md) — functional specs
- [Architecture](docs/ARCHITECTURE.md) — technical decisions
- [Roadmap](docs/ROADMAP.md) — what's next
- [Changelog](CHANGELOG.md) — version history

## License

[MIT](LICENSE) — Bahadır Gezer, 2026
