# Greenlight

An iOS weather app that answers one question: **is today a good day to go outside?**

Search for any city and Greenlight turns the raw forecast into a simple **Go / Caution / Stop** verdict for the day, with a short reason and a practical tip (like *"bring a rain layer"*), plus a forecast for the rest of the week.

Built with SwiftUI and live data from [Open-Meteo](https://open-meteo.com/).

<!-- Screenshots: add 2–3 simulator screenshots here, e.g.
<p align="center">
  <img src="screenshots/search.png" width="250">
  <img src="screenshots/forecast.png" width="250">
  <img src="screenshots/detail.png" width="250">
</p>
-->

## Features

- **City search** with live results from Open-Meteo's geocoding API
- **Today's verdict card**: Go, Caution, or Stop, with the reason and a recommendation
- **Weekly forecast**: a scrollable daily list
- **Day detail view**: high/low, feels-like, precipitation chance, rain total, wind speed, gusts, wind direction, and UV index
- **Saved cities**: pin your favorites and pick up where you left off with your last-viewed city
- **Custom animated graphics**: a precipitation arc and a wind dial with a direction arrow, both drawn in SwiftUI

## How the verdict works

Each day's forecast is scored on three outside factors: **temperature**, **rain**, and **wind**. Each one gets a green, yellow, or red level, and then they're combined:

| If… | Verdict |
|---|---|
| Any factor is red | 🔴 **Stop** |
| Any factor is yellow | 🟡 **Caution** |
| Everything is green | 🟢 **Go** |

## How it's built

- **SwiftUI** throughout, with `@AppStorage` for saved and last-viewed cities
- **async/await networking** kept in its own layer: views call `searchCities(query:count:)` and `getForecast(lat:lon:)` and never build requests themselves
- **Codable models** that match the API responses: `City`, `GeocodingResponse`, `ForecastResponse`, `DailyForecast`
- **Loading and error states**: a `ProgressView` while fetching, and readable error messages in the UI
- **Custom drawing**: `PrecipArc` and `WindDial` use `trim` and `AngularGradient`, and animate as values change

## Getting started

1. Clone the repo and open `Greenlight/Greenlight.xcodeproj` in Xcode.
2. Pick an iPhone simulator and press **Run**.

No API key needed: Open-Meteo is free and open.

## Credits

- Weather and geocoding data: [Open-Meteo](https://open-meteo.com/en/docs)
- App icon: designed by Beverly Mutuku in Canva

## About

Designed and built by **Beverly Mutuku**. It started as a project for CMSI 2022 (Mobile Application Development) at LMU.
