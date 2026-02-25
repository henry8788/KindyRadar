# CLAUDE.md
Project guidance for Claude when working with this repository.

## What is KindyRadar?
A Taiwan preschool violation tracker iOS app. Parents can search preschools and view violation records from Taiwan Ministry of Education open data.

## Tech Stack
- SwiftUI + MVVM + Combine + async/await
- iOS 16.0+, Xcode 16.4, Swift 5.10+
- No external dependencies (pure Swift only)

## Project Structure
```
KindyRadar/
├── Views/          SwiftUI screens
├── ViewModels/     Business logic + @Published
├── Models/         Data structures (Codable)
└── Services/       Network + 24-hour caching
```

## Data Sources
**Preschools (GeoJSON):**
```
https://kiang.github.io/ap.ece.moe.edu.tw/preschools.json
~6000 preschools, includes coordinates and basic info
```

**Violations (JSON):**
```
https://kiang.github.io/ap.ece.moe.edu.tw/punish_all.json
Violation records grouped by owner name
```

No API keys required — public open data.

## Architecture
MVVM with Combine:
- Services fetch data via `async/await`
- ViewModels expose `@Published` properties
- Views use `@StateObject` and react to changes
- 24-hour local cache (UserDefaults or FileManager)

## MVP Scope (v1.0)
**In scope:**
- List + search + filter
- Detail page with violations
- Pull-to-refresh
- 24-hour caching

**Out of scope (v1.1):**
- Push notifications
- Map view
- User accounts

## Constraints
- MUST write all UI text in Traditional Chinese
- MUST NOT use any third-party dependencies
- MUST NOT use English in user-facing strings, error messages, or labels
- NEVER suggest SwiftUI deprecated APIs (iOS 16.0 minimum)
- NEVER use DispatchQueue — use async/await instead

## Code Style
- `camelCase` for variables and functions
- `PascalCase` for types and structs
- Private properties prefixed with `_` (e.g. `_cache`)
- Prefer `guard let` over nested `if let`

## Development Guide
For detailed coding rules, see:
`.claude/skills/kindyradar-dev/SKILL.md`

This file contains:
- Modern concurrency patterns
- Combine usage
- SwiftUI best practices
- Code templates
- Chinese localization rules