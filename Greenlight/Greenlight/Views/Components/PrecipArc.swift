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

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 6)
            Circle()
                .trim(from: 0, to: probability)
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.3), color],
                        center: .center
                    ), style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: probability)
            //Text("\(Int(probability * 100))%")
                .font(.caption.weight(.semibold))
        }
        .frame(width: size, height: size)
    }
}

private func precipColor(pop: Int?) -> Color {
    let p = pop ?? 0
    switch p {
    case 0...10: return .secondary
    case 11...30: return .blue.opacity(0.7)
    case 31...60: return .blue
    default: return .indigo
    }
}
