//
//  ContentView.swift
//  Greenlight
//
//  Created by Beverly Mutuku on 2/12/26.
//

import SwiftUI

struct ContentView: View {
    
    // MARK: - Persistent Storage
    @AppStorage("savedCity") private var savedCityData: String = ""

    // MARK: - Search State
    @State private var query: String = ""
    @State private var cities: [City] = []
    
    // MARK: - UI State
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    // debounce: cancel the previous scheduled search when user keeps typing
    @State private var searchTask: Task<Void, Never>? = nil
    
    // MARK: - Derived State
    private var savedCity: City? { loadCity() }
    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Group {
                if let savedCity, trimmedQuery.isEmpty {
                    ForecastView(city: savedCity) {
                        clearSavedCityAndReturnToSearch()
                    }
                } else { searchUI }
            }
        }
    }

    // MARK: - Search UI
    private var searchUI: some View {
            VStack(alignment: .leading, spacing: 12) {
                
                // search field
                TextField("Search for a city", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)

                // loading spinner
                if isLoading {
                    HStack{ Spacer(); ProgressView(); Spacer() }
                }

                // error message (user-facing)
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .padding(.horizontal)
                }

                // results list
                List {
                    if !trimmedQuery.isEmpty {
                        Section("Results") {
                            ForEach(cities, id: \.id) { city in
                                NavigationLink {
                                    ForecastView(city: city, onChangeCity: nil)
                                } label: {
                                    Text("\(city.name), \(city.admin1 ?? city.country), \(city.country_code ?? "")")
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("City Search")
            .onChange(of: query) { _, newValue in
                scheduleSearch(newValue)
            }
        }
        
    // MARK: - Persistence
    private func loadCity() -> City? {
        guard let data = savedCityData.data(using: .utf8),
              let city = try? JSONDecoder().decode(City.self, from: data)
        else { return nil }
        return city
    }
    
    private func saveCity(_ city: City) {
        guard let data = try? JSONEncoder().encode(city),
              let string = String(data: data, encoding: .utf8)
        else { return }
        savedCityData = string
    }
    
    private func clearSavedCityAndReturnToSearch() {
        savedCityData = ""
        query = ""
        cities = []
        errorMessage = nil
        isLoading = false
    }
    
    // MARK: - Search Logic
    private func scheduleSearch(_ raw: String) {
        searchTask?.cancel()

        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // reset UI if the search box is empty
        if trimmed.isEmpty {
            cities = []
            errorMessage = nil
            isLoading = false
            return
        }
        
        // debounce: wait a bit before hitting the API
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000) // 0.35s
            if Task.isCancelled { return }
            await runSearch(trimmed)
        }
    }

    private func runSearch(_ trimmed: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let results = try await searchCities(query: trimmed, count: 25)
            if Task.isCancelled { return }
            
            // normalize once (for comparisons)
            let q = trimmed.lowercased()
            
            // keep prefix matches only
            let prefixFiltered = results.filter { $0.name.lowercased().hasPrefix(q) }
            
            // deduplicate by id
            var seen = Set<Int>()
            let deduped = prefixFiltered.filter { seen.insert($0.id).inserted }

            // sort: exact name > population > name
            let sorted = deduped.sorted {
                let aExact = $0.name.lowercased() == q
                let bExact = $1.name.lowercased() == q
                if aExact != bExact { return aExact && !bExact }

                let aPop = $0.population ?? -1
                let bPop = $1.population ?? -1
                if aPop != bPop { return aPop > bPop }

                return $0.name < $1.name
            }
            
            await MainActor.run {
                cities = sorted
                errorMessage = sorted.isEmpty ? "No results." : nil
                isLoading = false
            }
            
        } catch {
            if Task.isCancelled { return }
            await MainActor.run {
                cities = []
                errorMessage = "Couldn't load results. Try again."
                isLoading = false
            }
        }
    }
}

#Preview {
    ContentView()
}
