//
//  ContentView.swift
//  Greenlight
//
//  Created by Beverly Mutuku on 2/12/26.
//

import SwiftUI

struct ContentView: View {
    
    // user's search text
    @State private var query: String = ""
    
    // current list of results being shown
    @State private var cities: [City] = []
    
    // UI state flaps/messages
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    // used for debouncing (canceling old search if user keeps typing)
    @State private var searchTask: Task<Void, Never>? = nil

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

                // spinner while waiting for network results
                if isLoading {
                    HStack{
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding(.top, 6)
                }

                // user-facing error message
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .padding(.horizontal)
                }

                List {

                    // results list (buttons for user to tap)
                    Section("Results") {
                        ForEach(cities, id: \.id) { city in
                            NavigationLink {
                                ForecastView(city: city)
                            } label: {
                                Text("\(city.name), \(city.admin1 ?? city.country), \(city.country_code ?? "")")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("City Search")
        }
        // every time query changes, schedule a debounced search
        .onChange(of: query) { _, newValue in
            scheduleSearch(newValue)
        }
    }

    private func scheduleSearch(_ raw: String) {
        // cancel previous pending search (debounce)
        searchTask?.cancel()

        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // don't hit the API until user typed at least 3 characters
        // reduce jumpy error states
        if trimmed.count < 3 {
            cities = []
            errorMessage = nil
            isLoading = false
            return
        }
        
        // don't search on every keystroke
        // run search after a short delay
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000) // 0.35s debounce
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
            // ask API for candidates
            let results = try await searchCities(query: trimmed, count: 25)
            if Task.isCancelled { return }
            
            // normalize the query once for comparisons
            let q = trimmed
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            
            // show "No results" once user typed enough characters
            let minChars = 3
            let shouldShowNoResults = q.count >= minChars
            
            // filter to only cities whose name starts with what user typed
            // ex: "New York" should only show "New York..." and not "Florence"
            let prefixFiltered = results.filter {
                $0.name.lowercased().hasPrefix(q)
            }
            // remove duplicates by city id
            var seen = Set<Int>()
            let deduped = prefixFiltered.filter {
                seen.insert($0.id).inserted
            }

            // sorting priority:
            // 1) exact name match first (ex: "New York" == "New York")
            // 2) higher population next (more likely what user means)
            // 3) alphabetical as tie-breaker
            let filtered = deduped.sorted {
                let aExact = $0.name.lowercased() == q
                let bExact = $1.name.lowercased() == q
                if aExact != bExact { return aExact && !bExact }

                let aPop = $0.population ?? -1
                let bPop = $1.population ?? -1
                if aPop != bPop { return aPop > bPop }

                return $0.name < $1.name
            }
            
            await MainActor.run {
                cities = filtered
                errorMessage = (cities.isEmpty && shouldShowNoResults) ? "No results" : nil
                isLoading = false
            }
            
        } catch OpenMeteoAPIError.noResults {
            if Task.isCancelled { return }
            await MainActor.run {
                cities = []
                errorMessage = "No results"
                isLoading = false
            }
            
        } catch OpenMeteoAPIError.decodeFailed {
            print("Decode failed for query:", trimmed)
            if Task.isCancelled { return }
            await MainActor.run {
                cities = []
                errorMessage = nil
                isLoading = false
            }
            
        } catch {
            if Task.isCancelled { return }
            print("Search failed:", error)
            await MainActor.run {
                cities = []
                errorMessage = nil
                isLoading = false
            }
        }

        isLoading = false
    }
}

#Preview {
    ContentView()
}
