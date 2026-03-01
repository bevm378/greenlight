//
//  WindDial.swift
//  Greenlight
//
//  Created by Beverly Mutuku on 2/28/26.
//

import SwiftUI

struct WindDial: View {
    
    let mph: Double
    let color: Color
    var directionDeg: Double? = nil
    var maxMph: Double = 30
    var size: CGFloat = 36

    // normalize mph to 0...1 using maxMph as a reference
    private var t: Double {
        let denom = max(maxMph, 1)
        return min(max(mph / denom, 0), 1)
    }

    private var lineWidth: CGFloat {
        max(3, size * 0.16)
    }

    var body: some View {
        ZStack {
            // track
            Circle()
                .stroke(Color(.systemGray5), lineWidth: lineWidth)

            // progress arc
            Circle()
                .trim(from: 0, to: t)
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.25), color],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: t)

            // direction arrow
            if let directionDeg {
                Image(systemName: "arrow.up")
                    .font(.system(size: size * 0.28, weight: .semibold))
                    .rotationEffect(.degrees(directionDeg))
                    .foregroundStyle(color)
                    .opacity(0.9)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Wind")
        .accessibilityValue("\(Int(mph.rounded())) miles per hour")
    }
}
