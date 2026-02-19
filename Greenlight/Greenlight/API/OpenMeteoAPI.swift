//
//  OpenMeteoAPI.swift
//  Greenlight
//
//  Created by Beverly Mutuku on 2/14/26.
//

import Foundation

// base URLs
let OpenMeteoAPI_root = "https://api.open-meteo.com/v1"
let OpenMeteoAPI_endpoint = "\(OpenMeteoAPI_root)/forecast"

let OpenMeteoGeocoding_root = "https://geocoding-api.open-meteo.com/v1"
let OpenMeteoGeocoding_endpoint = "\(OpenMeteoGeocoding_root)/search"

// errors thrown from API layer
enum OpenMeteoAPIError: Error {
    case noResults              // decoded fine but results empty
    case decodeFailed           // response couldn't be decoded into models
    case unexpectedAPIError     // network/server error
}

// CITY SEARCH: turn a city name into a list of matching cities
func searchCities(query: String, count: Int = 10) async throws -> [City] {
    
    // normalize user input
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return [] }

    // build URL like:
    // https://geocoding-api.open-meteo.com/v1/search?name=...&count=...&language=en&format=json
    var components = URLComponents(string: OpenMeteoGeocoding_endpoint)
    components?.queryItems = [
        URLQueryItem(name: "name", value: trimmed),
        URLQueryItem(name: "count", value: String(count)),
        URLQueryItem(name: "language", value: "en"),
        URLQueryItem(name: "format", value: "json")
    ]

    // if URLComponents fails, programmer error
    guard let url = components?.url else {
        fatalError("URL didn't work :p... Check URLComponents/queryItems")
    }

    // make the request
    let (data, _) = try await URLSession.shared.data(from: url)

    // try decoding into our expected response type
    if let decoded = try? JSONDecoder().decode(GeocodingResponse.self, from: data) {
        let results = decoded.results ?? []
        if results.isEmpty { throw OpenMeteoAPIError.noResults }
        return results
    } else {
        
        // decoding failed
        throw OpenMeteoAPIError.decodeFailed
    }
}

// FORECAST: turn lat/lon into daily forecast data
func getForecast(lat: Double, lon: Double) async throws -> ForecastResponse {
    
    // build URL like:
    // https://api.open-meteo.com/v1/forecast?latitude=...&longitude=...&daily=...&timezone=auto
    var components = URLComponents(string: OpenMeteoAPI_endpoint)
    components?.queryItems = [
        URLQueryItem(name: "latitude", value: String(lat)),
        URLQueryItem(name: "longitude", value: String(lon)),
        URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min,precipitation_probability_max"),
        URLQueryItem(name: "timezone", value: "auto")
    ]

    guard let url = components?.url else {
        fatalError("URL didn't work :p... Check URLComponents/queryItems")
    }

    let (data, _) = try await URLSession.shared.data(from: url)

    if let decoded = try? JSONDecoder().decode(ForecastResponse.self, from: data) {
        return decoded
    } else {
        throw OpenMeteoAPIError.decodeFailed
    }
}
