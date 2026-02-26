# StackOverflow iOS App

Simple iOS app that loads Stack Overflow users from `https://api.stackexchange.com/2.3/users` and displays them in a table view using MVVM + Diffable Data Source.

## Requirements

- Xcode: **26.2** or newer
- iOS Simulator runtime: **iOS 26.2** (or compatible runtime installed in your Xcode)
- Swift: **5**

## Project Setup

1. Open [StackOverflow.xcodeproj](/Users/kamil.tomaszewski/Developer/StackOverflow/StackOverflow.xcodeproj).
2. Select scheme: **`StackOverflow`**.
3. Select an iOS Simulator device.
4. Run the app (`Cmd + R`).

## Architecture

- `UsersRepository`: Fetches users from Stack Exchange API.
- `UserListViewModel`: Holds UI state (`idle`, `loading`, `loaded`, `error`) and follow state.
- `UserListViewController`: Programmatic UI + state rendering.
- `UserListDataSourceAdapter`: Table view diffable data source + cell rendering.

## Running Tests

### From Xcode

1. Choose scheme: **`StackOverflow`**
2. Run tests with `Cmd + U`

### From terminal (all tests)

```bash
xcodebuild test \
  -project StackOverflow.xcodeproj \
  -scheme StackOverflow \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

### From terminal (unit tests target only)

```bash
xcodebuild test \
  -project StackOverflow.xcodeproj \
  -scheme StackOverflow \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:StackOverflowTests
```
