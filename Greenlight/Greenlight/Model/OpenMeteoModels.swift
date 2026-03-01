//
//  OpenMeteoModels.swift
//  Greenlight
//
//  Created by Beverly Mutuku on 2/14/26.
//

import Foundation

// MARK: - Geocoding

// Open-Meteo geocoding returns `{ "results": [...] }` or no results
struct GeocodingResponse: Hashable, Codable {
    let results: [City]?
}

// one matching city from geocoding search
struct City: Hashable, Codable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String
    let country_code: String?
    let admin1: String?      // state/region
    let population: Int?
    let timezone: String?
}


// MARK: - Forecast

// forecast response wrapper for the `/forecast` endpoint
struct ForecastResponse: Hashable, Codable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let daily: DailyForecast
}

// daily fields requested in forecast API call
struct DailyForecast: Hashable, Codable {
    let time: [String]
    let temperature_2m_max: [Double]
    let temperature_2m_min: [Double]
    let apparent_temperature_max: [Double]
    let apparent_temperature_min: [Double]
    let precipitation_probability_max: [Int]?
    let rain_sum: [Double]?
    let wind_speed_10m_max: [Double]?
    let wind_direction_10m_dominant: [Double]?
    let wind_gusts_10m_max: [Double]?
    let uv_index_max: [Double]?
}
