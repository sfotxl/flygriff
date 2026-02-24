# FlyGriff (SwiftUI)

Native iOS app for FlyGriff using SwiftUI and Supabase.

## Project layout
- `FlyGriff.xcodeproj`: Xcode project
- `FlyGriffSwift/`: app source files

## Configure Supabase
In `FlyGriffSwift/Info.plist`, set:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

## Build and run
1. Open `FlyGriff.xcodeproj` in Xcode.
2. Select the `FlyGriff` scheme.
3. Build/run on iOS Simulator or device.

## Current app features
- Home tab with intro content
- Explore tab with Supabase flight fetch and world-map route plotting
- Add tab with native form that inserts a flight record into `FlightsA`