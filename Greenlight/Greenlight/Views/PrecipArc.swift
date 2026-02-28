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
            Text("\(Int(probability * 100))%")
                .font(.caption.weight(.semibold))
        }
        .frame(width: 36, height: 36)
    }
}
