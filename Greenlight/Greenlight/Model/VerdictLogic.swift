//
//  VerdictLogic.swift
//  Greenlight
//
//  Created by Beverly Mutuku on 2/27/26.
//

import SwiftUI

// MARK: - Verdict Types

enum VerdictLevel: Equatable {
    case green, yellow, red

    var title: String {
        switch self {
        case .green: return "Go"
        case .yellow: return "Caution"
        case .red: return "Stop"
        }
    }

    var color: Color {
        switch self {
        case .green: return .green
        case .yellow: return .yellow
        case .red: return .red
        }
    }
}

struct Verdict: Equatable {
    let level: VerdictLevel
    let feelsLikeLine: String
    let whyLine: String
    let recommendation: String
    let tempLevel: VerdictLevel?
    let rainLevel: VerdictLevel?
    let windLevel: VerdictLevel?
}

// MARK: - Logic

func makeVerdict(
    feelsLikeHighF: Double?,
    feelsLikeLowF: Double?,
    actualHighF: Double?,
    actualLowF: Double?,
    popMax: Int?,
    rainInches: Double?,
    windMph: Double?
) -> Verdict {

    // temperature flags
    var tempLevel: VerdictLevel? = nil
    if let hi = actualHighF {
        if hi <= 25 { tempLevel = .red }
        else if hi <= 40 { tempLevel = .yellow }
    }
    if let lo = actualLowF, lo <= 25, tempLevel != .red {
        tempLevel = .yellow
    }

    // rain flags
    var rainLevel: VerdictLevel? = nil
    if let rain = rainInches, rain >= 0.50 {
        rainLevel = .red
    } else if (rainInches ?? 0) >= 0.10 || (popMax ?? 0) >= 40 {
        rainLevel = .yellow
    }

    // wind flags
    var windLevel: VerdictLevel? = nil
    if let wind = windMph, wind >= 25 {
        windLevel = .red
    } else if let wind = windMph, wind >= 15 {
        windLevel = .yellow
    }

    // overall verdict: any red -> red; else any yellow -> yellow; else green
    let level: VerdictLevel = {
        if tempLevel == .red || rainLevel == .red || windLevel == .red { return .red }
        if tempLevel == .yellow || rainLevel == .yellow || windLevel == .yellow { return .yellow }
        return .green
    }()

    let feelsLikeLine: String = {
        if let hi = feelsLikeHighF, let lo = feelsLikeLowF {
            return "Feels like \(Int(hi.rounded()))°  /  \(Int(lo.rounded()))°"
        }
        if let hi = feelsLikeHighF { return "Feels like ~\(Int(hi.rounded()))°" }
        return "Feels like --"
    }()

    let whyLine: String = {
        switch level {
        case .green:
            return "Clear conditions"
        case .yellow:
            if tempLevel == .yellow { return "Chilly" }
            if rainLevel == .yellow { return "Light rain" }
            if windLevel == .yellow { return "Breezy" }
            return "Mixed conditions"
        case .red:
            if tempLevel == .red { return "Frigid" }
            if rainLevel == .red { return "Heavy rain" }
            if windLevel == .red { return "Windy" }
            return "Harsh conditions"
        }
    }()

    let recommendation: String = {
        switch level {
        case .green:
            return "It's looking pretty good outside!"
        case .yellow:
            if tempLevel == .yellow { return "It's OK outside, but add a warm layer" }
            if rainLevel == .yellow { return "It's OK outside, but bring a rain layer" }
            if windLevel == .yellow { return "It's OK outside, but take sheltered routes" }
            return "It's OK outside, but keep plans flexible"
        case .red:
            return "It's better to stay indoors"
        }
    }()

    return Verdict(
        level: level,
        feelsLikeLine: feelsLikeLine,
        whyLine: whyLine,
        recommendation: recommendation,
        tempLevel: tempLevel,
        rainLevel: rainLevel,
        windLevel: windLevel
    )
}

// MARK: - UI Helpers (chip tinting)

func chipTint(for level: VerdictLevel?) -> Color {
    guard let level else { return .secondary } // neutral when not triggered or unknown
    switch level {
    case .green: return .secondary
    case .yellow: return Color(red: 0.8, green: 0.67, blue: 0.0)
    case .red: return .red
    }
}
