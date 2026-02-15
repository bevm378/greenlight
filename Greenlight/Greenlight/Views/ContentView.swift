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
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    @State private var searchTask: Task<Void, Never>? = nil
    @State private var selectedCity: City? = nil

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Search for a city", text: $query)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)

                if isLoading {
                    HStack{
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding(.top, 6)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .padding(.horizontal)
                }

                List {
                    if let selectedCity {
                        Section("Selected") {
                            Text("\(selectedCity.name), \(selectedCity.admin1 ?? selectedCity.country)")
                        }
                    }

                    Section("Results") {
                        ForEach(cities, id: \.id) { city in
                            Button {
                                selectedCity = city
                            } label: {
                                Text("\(city.name), \(city.admin1 ?? city.country), \(city.country_code ?? "")")
                            }
                        }
                    }
                }
            }
            .navigationTitle("City Search")
        }
        .onChange(of: query) { _, newValue in
            scheduleSearch(newValue)
        }
    }

    private func scheduleSearch(_ raw: String) {
        searchTask?.cancel()

        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            cities = []
            errorMessage = nil
            isLoading = false
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000) // debounce
            if Task.isCancelled { return }
            await runSearch(trimmed)
        }
    }

    @MainActor
    private func runSearch(_ trimmed: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let results = try await searchCities(query: trimmed, count: 10)
            var seen = Set<Int>()
            cities = results.filter { seen.insert($0.id).inserted }
        } catch OpenMeteoAPIError.noResults {
            cities = []
            errorMessage = "No results"
        } catch OpenMeteoAPIError.decodeFailed {
            cities = []
            errorMessage = "Couldn’t decode the response"
        } catch {
            cities = []
            errorMessage = "Something went wrong"
        }

        isLoading = false
    }
}

#Preview {
    ContentView()
}
