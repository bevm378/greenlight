//
//  OpenMeteoAPI.swift
//  Greenlight
//
//  Created by Beverly Mutuku on 2/14/26.
//

import Foundation

private let geocodingBaseURL = "https://geocoding-api.open-meteo.com/v1/search"

func searchCities(query: String) async throws -> [City] {
    let urlString = "\(geocodingBaseURL)?name=\(query)&count=5"
    
    guard let url = URL(string: urlString) else {
        throw URLError(.badURL)
    }
    
    let(data, _) = try await URLSession.shared.data(from: url)
    let decoded = try JSONDecoder().decode(GeocodingResponse.self,from: data)
    return decoded.results
}
