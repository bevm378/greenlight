//
//  ForecastView.swift
//  Greenlight
//
//  Created by Beverly Mutuku on 2/19/26.
//

import SwiftUI

struct ForecastView: View {
    let city: City

    // UI state
    @State private var isLoading = false
    @State private var forecast: ForecastResponse? = nil
    @State private var errorMessage: String? = nil
    
    // parse API dates like "2026-02-19"
    private static let apiDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .iso8601)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    // display dates like "Thu, Feb 19"
    private static let displayDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateFormat = "EEE, MMM d"
        return df
    }()

    // nice date string
    private func prettyDate(_ apiDate: String) -> String {
        guard let d = Self.apiDateFormatter.date(from: apiDate) else { return apiDate }
        return Self.displayDateFormatter.string(from: d)
    }

    // format temps like " 5°" or "10°"
    private func tempString(_ value: Double) -> String {
        String(format: "%2d°", Int(value.rounded()))
    }

    // format POP like " 10%" or "100%"
    private func popString(_ value: Int) -> String {
        String(format: "%3d%%", value)
    }

    private func forecastRow(dateText: String, hi: Double, lo: Double, pop: Int?) -> some View {
        
        
        HStack(spacing: 10) {
            
            //left: fixed-width date column
            Text(dateText)
                .frame(width: 100, alignment: .leading)
                .lineLimit(1)

            // middle: fixed-width temps
            HStack(spacing: 6) {
                Text("H\(tempString(hi))")
                Text("L\(tempString(lo))")
                    .foregroundStyle(.secondary)
            }
            .font(.system(.body, design: .monospaced))
            .lineLimit(1)
            .fixedSize(horizontal: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/, vertical: false)
            .frame(width: 100, alignment: .trailing)

            // right: fixed-width precip
            HStack(spacing: 6) {
                Image(systemName: "umbrella.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 14, alignment: .center)

                Text(pop.map(popString) ?? "")
            }
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(.secondary)
            .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, 6)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // header
            Text("\(city.name), \(city.admin1 ?? city.country)")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)

            // loading spinner
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.top, 12)
            }

            // error
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .padding(.horizontal)
            }
            
            // forecast list
            if let forecast {
                List {
                    Section("Daily Forecast") {
                        ForEach(forecast.daily.time.indices, id: \.self) { i in
                            forecastRow(
                                dateText: prettyDate(forecast.daily.time[i]),
                                hi: forecast.daily.temperature_2m_max[i],
                                lo: forecast.daily.temperature_2m_min[i],
                                pop: forecast.daily.precipitation_probability_max?[safe: i]
                            )
                        }
                    }
                }
            } else {
                Spacer()
            }
        }
        .navigationTitle("Forecast")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadForecast()
        }
    }
    
    @MainActor
    private func loadForecast() async {
        isLoading = true
        errorMessage = nil
        forecast = nil
        
        do {
            forecast = try await getForecast(lat: city.latitude, lon: city.longitude)
        } catch {
            print("Forecast failed:", error)
            errorMessage = "Couldn’t load forecast right now"
        }
        
        isLoading = false
    }
}

// safe indexing helper
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ForecastView(city: City(
        id: 1,
        name: "Secaucus",
        latitude: 40.7895,
        longitude: -74.0565,
        country: "United States",
        country_code: "US",
        admin1: "New Jersey",
        population: nil,
        timezone: nil
    ))
}
