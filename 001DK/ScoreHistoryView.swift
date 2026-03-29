//
//  ScoreHistoryView.swift
//  001DK
//
//  Created by Aytac Akyildiz on 29/03/2026.
//

import SwiftUI

struct ScoreHistoryView: View {
    var body: some View {
        VStack {
            if true {  // We'll replace this with real data later
                List {
                    Text("No tests completed yet")
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text("Your past practice test results will appear here")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .navigationTitle("My Scores")
    }
}
