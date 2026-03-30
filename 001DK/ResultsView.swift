//
//  ResultsView.swift
//  001DK
//
//  Created by Aytac Akyildiz on 29/03/2026.
//


import SwiftUI

struct ResultsView: View {
    let questions: [Question]
    let userAnswers: [String: Int?]
    
    @EnvironmentObject private var navController: NavigationController
    
    var score: Int {
        var correct = 0
        for question in questions {
            if let selected = userAnswers[question.id], selected == question.correctIndex {
                correct += 1
            }
        }
        return correct
    }
    
    var passed: Bool {
        score >= 36
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                VStack(spacing: 16) {
                    Text("\(score)/\(questions.count)")
                        .font(.system(size: 70, weight: .bold, design: .rounded))
                        .foregroundStyle(passed ? .green : .red)
                    
                    Text(passed ? "You Passed! 🎉" : "Not yet — keep practicing")
                        .font(.title)
                        .fontWeight(.semibold)
                }
                
                HStack(spacing: 40) {
                    StatView(title: "Correct", value: "\(score)", color: .green)
                    StatView(title: "Wrong", value: "\(questions.count - score)", color: .red)
                }
                
                Text("Detailed review with explanations coming soon...")
                    .foregroundStyle(.secondary)
                    .italic()
                
                Button("Back to Home") {
                    navController.popToRoot()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 30)
            }
            .padding()
        }
        .navigationTitle("Test Results")
        .navigationBarBackButtonHidden(true)
    }
}

struct StatView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title.bold())
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
