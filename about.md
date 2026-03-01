# Greenlight

Greenlight is an iOS weather app that answers one simple question:

**“Is today a good day to go outside?”**

You search for a city, load the forecast, and get a clear **Go / Caution / Stop** verdict for the day (and for each day in the upcoming forecast). The verdict is based on practical “outside factors” like temperature, rain, and wind, and it also gives a short reason + recommendation (ex: “bring a rain layer”).

## What the app does
- City search with live API results (debounced so it doesn’t spam requests)
- A “Today” verdict card with quick metrics (high/low, precip, wind + direction)
- A daily forecast list you can tap into for full day details (includes gusts, UV, rain total)
- Save cities (pin) + keep a “Continue” city (last viewed) using `@AppStorage`
- Visual indicators (custom SwiftUI graphics) for precip and wind

## API used
This app uses the **Open-Meteo** public API:
- **Geocoding API** for searching cities by name
- **Weather Forecast API** for daily forecast values (temperature, feels-like, rain, wind, gusts, wind direction, UV)

Open-Meteo documentation:
https://open-meteo.com/en/docs

## How the verdict works
The app computes a verdict from daily forecast values:
- **Temperature**: very cold or chilly days raise the warning level
- **Rain**: higher precipitation probability raise the warning level
- **Wind**: stronger wind raises the warning level

Overall verdict logic:
- If any category hits “red” → **Stop**
- Else if any category hits “yellow” → **Caution**
- Else → **Go**

## SwiftUI + networking notes
- API calls are implemented as **async/await** functions (`searchCities`, `getForecast`)
- Views show **ProgressView** while waiting for network calls
- Errors are displayed to the user with simple messaging
- Custom graphics include:
  - `PrecipArc` (animated circular arc for precipitation probability)
  - `WindDial` (animated arc + optional direction arrow)

## Credits
- **Weather data + geocoding:** Open-Meteo (see docs link above)
- **App icon:** Designed by me in Canva (2026)

## Author
- Beverly Mutuku — 100% of design and implementation (solo project)
