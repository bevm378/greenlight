//
//  ContentView.swift
//  Greenlight
//
//  Created by Beverly Mutuku on 2/12/26.
//

import SwiftUI

struct ContentView: View {
    @State private var cities: [City] = []

    var body: some View {
        VStack {
            Text("City search demo")

            List(cities, id: \.self) { city in
                Text("\(city.name), \(city.country)")
            }
        }
        .task {
            do {
                cities = try await searchCities(query: "Los Angeles")
            } catch {
                print(error)
            }
        }
    }
}

#Preview {
    ContentView()
}
