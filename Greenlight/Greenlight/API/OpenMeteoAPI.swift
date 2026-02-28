//
//  OpenMeteoAPI.swift
//  Greenlight
//
//  Created by Beverly Mutuku on 2/14/26.
//

import Foundation

// MARK: - Endpoints (Open-Meteo)

let OpenMeteoAPI_root = "https://api.open-meteo.com/v1"
let OpenMeteoAPI_endpoint = "\(OpenMeteoAPI_root)/forecast"

let OpenMeteoGeocoding_root = "https://geocoding-api.open-meteo.com/v1"
let OpenMeteoGeocoding_endpoint = "\(OpenMeteoGeocoding_root)/search"

// MARK: - API Errors

enum OpenMeteoAPIError: Error {
    case noResults              // decoded fine, but no city matches
    case decodeFailed           // data came back, but didn't match models
    case unexpectedAPIError     // something else went wrong (bad URL, network, etc.)
}

// MARK: - City Search (name -> matching cities)

func searchCities(query: String, count: Int = 10) async throws -> [City] {
    
    // normalize user input
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return [] }

    // example:
    // https://geocoding-api.open-meteo.com/v1/search?name=...&count=...&language=en&format=json
    var components = URLComponents(string: OpenMeteoGeocoding_endpoint)
    components?.queryItems = [
        URLQueryItem(name: "name", value: trimmed),
        URLQueryItem(name: "count", value: String(count)),
        URLQueryItem(name: "language", value: "en"),
        URLQueryItem(name: "format", value: "json")
    ]

    guard let url = components?.url else {
        fatalError("URL didn't work :p")
    }

    // make request
    let (data, _) = try await URLSession.shared.data(from: url)

    // try decoding into response wrapper
    guard let decoded = try? JSONDecoder().decode(GeocodingResponse.self, from: data) else {
        fatalError("URL didn't work :p")
    }
    
    let results = decoded.results ?? []
    if results.isEmpty { throw OpenMeteoAPIError.noResults }
    return results
}

// MARK: - Forecast (lat/lon -> daily forecast)
func getForecast(lat: Double, lon: Double) async throws -> ForecastResponse {
    
    // example:
    // https://api.open-meteo.com/v1/forecast?latitude=...&longitude=...&daily=...&timezone=auto
    var components = URLComponents(string: OpenMeteoAPI_endpoint)
    components?.queryItems = [
        URLQueryItem(name: "latitude", value: String(lat)),
        URLQueryItem(name: "longitude", value: String(lon)),
        
        // daily fields wanted
        URLQueryItem(
            name: "daily",
            value: [
                "temperature_2m_max",
                "temperature_2m_min",
                "apparent_temperature_max",
                "apparent_temperature_min",
                "precipitation_probability_max",
                "rain_sum",
                "wind_speed_10m_max",
                "wind_direction_10m_dominant",
                "wind_gusts_10m_max"
            ].joined(separator: ",")
        ),

        // units
        URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
        URLQueryItem(name: "wind_speed_unit", value: "mph"),
        URLQueryItem(name: "precipitation_unit", value: "inch"),

        // use local timezone for chosen location
        URLQueryItem(name: "timezone", value: "auto")
    ]

    guard let url = components?.url else {
        throw OpenMeteoAPIError.unexpectedAPIError
    }

    let (data, _) = try await URLSession.shared.data(from: url)

    guard let decoded = try? JSONDecoder().decode(ForecastResponse.self, from: data) else {
        throw OpenMeteoAPIError.decodeFailed
    }
    
    return decoded
}
