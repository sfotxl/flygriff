# Migration Summary

React Native/Expo has been decommissioned from this repository.

## Removed
- Expo app structure (`app/`, `components/`, `hooks/`, etc.)
- JavaScript/TypeScript build/dependency files (`package.json`, lockfile, Expo configs)

## Added
- Native SwiftUI app source in `FlyGriffSwift/`
- Xcode project in `FlyGriff.xcodeproj`
- Supabase fetch + insert flows for `FlightsA`

## Important
The insert payload currently uses columns:
- `airline`
- `flight_number`
- `date`
- `from_airport_code`
- `to_airport_code`
- `trip_type`

If your Supabase schema uses different names, update `NewFlightPayload` in `FlyGriffSwift/Services/FlightService.swift`.