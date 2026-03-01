# Greenlight

Greenlight is an iOS weather app that answers one simple question:

**“Is today a good day to go outside?”**

Search for a city, load the forecast, and Greenlight gives a **Go / Caution / Stop** verdict for the day! The verdict is based on “outside factors” like temperature, rain, and wind, and is paired with a short reason and practical recommendation (ex: “bring a rain layer”).

## What the app does

- **City search (user input → API request):** type a city name and get live results from Open-Meteo’s geocoding API  
- **Forecast screen:** shows today’s verdict card + a scrollable daily forecast list  
- **Day detail screen:** shows expanded daily metrics (high/low, precip %, wind, gusts, wind direction, UV, and rain total)  
- **Saved cities + Continue:** pin/unpin cities and keep a “last viewed” city using `@AppStorage`

## How the verdict works

Greenlight computes category levels from three daily forecast values, then rolls them into one verdict:

- **Temperature** (too cold → caution/stop)
- **Rain** (higher precipitation probability → caution/stop)
- **Wind** (higher wind speed → caution/stop)

Overall verdict rule:
- Any **red** category → **Stop**
- Else any **yellow** category → **Caution**
- Else → **Go**

- ## API used
- **Geocoding API** (`/search`) for city lookup by name  
- **Weather Forecast API** (`/forecast`) for daily forecast values, including:
  - temperature highs/lows
  - apparent temperature highs/lows (feels-like)
  - precipitation probability max
  - rain sum
  - wind speed max
  - wind gusts max
  - wind direction dominant
  - UV index max

Open-Meteo documentation:  
https://open-meteo.com/en/docs

## SwiftUI + async networking (rubric callouts)

- **Models as Swift structs:** `City`, `ForecastResponse`, `DailyForecast`, `GeocodingResponse`
- **Networking abstraction:** all networking lives in async functions:
  - `searchCities(query:count:)`
  - `getForecast(lat:lon:)`
- **Progress feedback:** `ProgressView` shows during fetch/search
- **User-facing error handling:** errors display as simple messages in the UI (not just `print`)
- **Animations/transitions beyond defaults:** animated arc dials (see below)

## Programmed graphics + animation

The UI includes custom SwiftUI drawing with paths/gradients + animation:

- `PrecipArc`  
  - circular arc with `trim` and `AngularGradient`  
  - animates as probability changes  
- `WindDial`  
  - circular arc with `trim` and `AngularGradient`  
  - optional direction arrow that rotates based on wind direction  


## Credits

- Weather + geocoding data: **Open-Meteo**
- App icon: created by **me** using **Canva** (2026)


## Who did what

- **Beverly Mutuku** — design + implementation (solo project)
