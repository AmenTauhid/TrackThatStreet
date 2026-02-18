# TrackThatStreet

A real-time TTC streetcar tracker for iOS. See where every streetcar is, get arrival predictions, and spot service issues at a glance.

## Features

- **Live tracking** of all 9 TTC streetcar routes (501, 503, 504, 505, 506, 509, 510, 511, 512)
- **Interactive map** with color-coded vehicle positions and route filtering
- **Arrival predictions** with live countdown timers
- **Service status** indicators (good, fair, poor) for each route
- **Bunching and gap detection** with alert banners
- **Offline support** via cached data
- **Auto-refresh** every 25 seconds

## Screenshots

| Routes | Detail | Map |
|--------|--------|-----|
| Route list with status badges and vehicle counts | Predictions, direction picker, and alerts | All vehicles plotted across Toronto |

## Architecture

MVVM with async/await. Data flows from the [NextBus XML API](https://retro.umoiq.com/service/publicXMLFeed) through XML parsers into observable view models.

```
Models      Sendable structs (Vehicle, Route, Prediction, etc.)
Services    API client, XML parsers, cache, service analyzer
ViewModels  @Observable classes driving each screen
Views       SwiftUI with MapKit integration
```

## Requirements

- iOS 18+
- Xcode 26+
- Swift 6

## Getting Started

1. Clone the repo
2. Open `TrackThatStreet.xcodeproj`
3. Build and run on a simulator or device

No API keys or configuration needed.

## License

MIT
