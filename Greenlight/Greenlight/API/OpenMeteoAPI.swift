//
//  OpenMeteoAPI.swift
//  Greenlight
//
//  Created by Beverly Mutuku on 2/14/26.
//

import Foundation

let OpenMeteoAPI_root = "https://api.open-meteo.com/v1"
let OpenMeteoAPI_endpoint = "\(OpenMeteoAPI_root)/forecast"

let OpenMeteoGeocoding_root = "https://geocoding-api.open-meteo.com/v1"
let OpenMeteoGeocoding_endpoint = "\(OpenMeteoGeocoding_root)/search"

enum OpenMeteoAPIError: Error {
    case noResults
    case decodeFailed
    case unexpectedAPIError
}

// city name -> list of matching cities
func searchCities(query: String, count: Int = 10) async throws -> [City] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return [] }

    var components = URLComponents(string: OpenMeteoGeocoding_endpoint)
    components?.queryItems = [
        URLQueryItem(name: "name", value: trimmed),
        URLQueryItem(name: "count", value: String(count)),
        URLQueryItem(name: "language", value: "en"),
        URLQueryItem(name: "format", value: "json")
    ]

    guard let url = components?.url else {
        fatalError("Should never happen, but just in case...URL didn't work :p")
    }

    let (data, _) = try await URLSession.shared.data(from: url)

    if let decoded = try? JSONDecoder().decode(GeocodingResponse.self, from: data) {
        let results = decoded.results ?? []
        if results.isEmpty { throw OpenMeteoAPIError.noResults }
        return results
    } else {
        throw OpenMeteoAPIError.decodeFailed
    }
}

// lat/lon -> daily forecast
func getForecast(lat: Double, lon: Double) async throws -> ForecastResponse {
    var components = URLComponents(string: OpenMeteoAPI_endpoint)
    components?.queryItems = [
        URLQueryItem(name: "latitude", value: String(lat)),
        URLQueryItem(name: "longitude", value: String(lon)),
        URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min,precipitation_probability_max"),
        URLQueryItem(name: "timezone", value: "auto")
    ]

    guard let url = components?.url else {
        fatalError("Should never happen, but just in case...URL didn't work :p")
    }

    let (data, _) = try await URLSession.shared.data(from: url)

    if let decoded = try? JSONDecoder().decode(ForecastResponse.self, from: data) {
        return decoded
    } else {
        throw OpenMeteoAPIError.decodeFailed
    }
}
