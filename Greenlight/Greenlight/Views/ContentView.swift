//
//  ContentView.swift
//  Greenlight
//
//  Created by Beverly Mutuku on 2/12/26.
//

import SwiftUI

struct ContentView: View {
    @State private var query: String = ""
    @State private var cities: [City] = []

    @State private var selectedCity: City?
    @State private var forecast: ForecastResponse?

    var body: some View {
        VStack {
            Text("City Search")

            TextField("Search city...", text: $query)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            List(cities, id: \.self) { city in
                Button {
                    selectedCity = city
                    Task {
                        do {
                            forecast = try await getForecast(lat: city.latitude, lon: city.longitude)
                        } catch {
                            print(error)
                        }
                    }
                } label: {
                    Text("\(city.name), \(city.country)")
                }
            }

            if let city = selectedCity, let f = forecast {
                let d = f.daily
                VStack(alignment: .leading, spacing: 6) {
                    Text("Forecast for \(city.name)")
                        .font(.headline)

                    // show day 0 as a proof-of-life
                    if !d.time.isEmpty {
                        Text("Date: \(d.time[0])")
                        Text("High: \(d.temperature_2m_max[0])°")
                        Text("Low: \(d.temperature_2m_min[0])°")
                        if let pop = d.precipitation_probability_max, !pop.isEmpty {
                            Text("Rain chance: \(pop[0])%")
                        }
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    ContentView()
}
