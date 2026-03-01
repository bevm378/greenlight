//
//  PrecipArc.swift
//  Greenlight
//
//  Created by Beverly Mutuku on 2/28/26.
//

import SwiftUI

struct PrecipArc: View {
    
    let probability: Double
    let color: Color
    var size: CGFloat = 36

    // clamp to 0...1 so bad/empty data can't break arc
    private var p: Double {
        min(max(probability, 0), 1)
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
                .trim(from: 0, to: p)
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.4), color],
                        center: .center
                    ), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: p)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Precipitation probability")
        .accessibilityValue("\(Int(p * 100)) percent")
    }
}
