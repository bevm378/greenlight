//
//  OpenMeteoModels.swift
//  Greenlight
//
//  Created by Beverly Mutuku on 2/14/26.
//

import Foundation

struct GeocodingResponse: Codable {
    let results: [City]
}

struct City: Codable, Hashable {
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String
}
