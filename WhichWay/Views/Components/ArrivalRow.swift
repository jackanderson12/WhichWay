//
//  ArrivalRow.swift
//  WhichWay
//
//  Created by Jack Anderson on 2/5/26.
//

import SwiftUI

struct ArrivalRow: View {
    let arrival: StationArrival

    var body: some View {
        HStack(spacing: 12) {
            // Route badge
            ZStack {
                Circle()
                    .fill(Color(hex: arrival.routeColor))
                    .frame(width: 32, height: 32)

                Text(arrival.routeShortName)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: arrival.routeTextColor))
            }

            // Direction
            VStack(alignment: .leading, spacing: 2) {
                Text(arrival.directionLabel)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }

            Spacer()

            // Countdown
            Text(arrival.arrivalDescription)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(arrival.minutesAway <= 1 ? .red : .primary)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }
}
