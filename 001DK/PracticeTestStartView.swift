//
//  PracticeTestStartView.swift
//  001DK
//
//  Created by Aytac Akyildiz on 29/03/2026.
//

import SwiftUI

struct PracticeTestStartView: View {
    @EnvironmentObject private var navController: NavigationController
    
    var body: some View {
        VStack(spacing: 40) {
            Image(systemName: "scroll.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            
            VStack(spacing: 12) {
                Text("Practice Test")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("45 questions • 45 minutes")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            
            Text("This test follows the real Indfødsretsprøven format")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Spacer()
            
            Button {
                navController.path.append(AppRoute.practiceTest)
            } label: {
                Text("Start New Test")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 40)
            
            Text("You can skip questions, go back, and change answers during the test")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .navigationTitle("New Practice Test")
    }
}
