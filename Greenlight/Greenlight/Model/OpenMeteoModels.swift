//
//  OpenMeteoModels.swift
//  Greenlight
//
//  Created by Beverly Mutuku on 2/14/26.
//

import Foundation

// geocoding

struct GeocodingResponse: Hashable, Codable {
    let results: [City]?
}

struct City: Hashable, Codable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String
    let country_code: String?
    let admin1: String?
    let population: Int?
    let timezone: String?
}

// forecast

struct ForecastResponse: Hashable, Codable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let daily: DailyForecast
}

struct DailyForecast: Hashable, Codable {
    let time: [String]
    let temperature_2m_max: [Double]
    let temperature_2m_min: [Double]
    let precipitation_probability_max: [Int]?
}
