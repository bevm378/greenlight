//
//  OpenMeteoModels.swift
//  Greenlight
//
//  Created by Beverly Mutuku on 2/14/26.
//

import Foundation

// geocoding response wrapper (open-meteo returns { results: [...] } or no results)
struct GeocodingResponse: Hashable, Codable {
    let results: [City]?
}

// one city result from geocoding search
struct City: Hashable, Codable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String
    let country_code: String?
    let admin1: String?         // state/region
    let population: Int?
    let timezone: String?
}

// forecast response wrapper
struct ForecastResponse: Hashable, Codable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let daily: DailyForecast
}

// "daily" portion requested in API call
struct DailyForecast: Hashable, Codable {
    let time: [String]
    let temperature_2m_max: [Double]
    let temperature_2m_min: [Double]
    let apparent_temperature_max: [Double]
    let apparent_temperature_min: [Double]
    let precipitation_probability_max: [Int]?
    let rain_sum: [Double]?
    let wind_speed_10m_max: [Double]?
}
