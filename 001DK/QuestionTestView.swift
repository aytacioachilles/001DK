//
//  QuestionTestView.swift
//  001DK
//
//  Created by Aytac Akyildiz on 29/03/2026.
//

import SwiftUI

struct QuestionTestView: View {
    @StateObject private var questionManager = QuestionManager()
    @State private var testQuestion: Question? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("QuestionView Test")
                    .font(.largeTitle.bold())
                
                if let question = testQuestion {
                    QuestionView(
                        viewModel: QuestionViewModel(
                            question: question,
                            showFeedback: true   // Study mode = immediate feedback
                        )
                    )
                } else {
                    Text("Loading test question...")
                        .foregroundStyle(.secondary)
                }
                
                Button("Load Another Random Question") {
                    loadRandomQuestion()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Question View Test")
        }
        .task {
            await questionManager.loadQuestions()
            loadRandomQuestion()
        }
    }
    
    private func loadRandomQuestion() {
        guard !questionManager.allQuestions.isEmpty else { return }
        
        let randomIndex = Int.random(in: 0..<questionManager.allQuestions.count)
        testQuestion = questionManager.allQuestions[randomIndex]
    }
}
