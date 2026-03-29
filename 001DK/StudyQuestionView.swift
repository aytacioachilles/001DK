//
//  StudyQuestionView.swift
//  001DK
//
//  Created by Aytac Akyildiz on 29/03/2026.
//

import SwiftUI

struct StudyQuestionView: View {
    let topic: String                    // This will be lowercase: "culture", "history", etc.
    
    @StateObject private var questionManager = QuestionManager()
    @State private var currentQuestions: [Question] = []
    @State private var currentIndex = 0
    @State private var showCompletion = false
    
    var body: some View {
        VStack {
            if showCompletion {
                completionView
            } else if !currentQuestions.isEmpty && currentIndex < currentQuestions.count {
                studyQuestionContent
            } else {
                VStack(spacing: 20) {
                    ProgressView()
                    Text("Loading questions for \(topic)...")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(topic.capitalized)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadQuestionsForTopic()
        }
    }
    
    private var studyQuestionContent: some View {
        VStack(spacing: 24) {
            // Progress
            HStack {
                Text("Question \(currentIndex + 1) of \(currentQuestions.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                ProgressView(value: Double(currentIndex + 1), total: Double(currentQuestions.count))
                    .frame(width: 140)
            }
            .padding(.horizontal)
            
            // The Question
            if currentIndex < currentQuestions.count {
                QuestionView(
                    viewModel: QuestionViewModel(
                        question: currentQuestions[currentIndex],
                        showFeedback: true
                    )
                )
            }
            
            Spacer()
            
            Button(action: nextQuestion) {
                Text(currentIndex == currentQuestions.count - 1 ? "Finish Topic" : "Next Question")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(14)
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    private var completionView: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            
            Text("Topic Completed!")
                .font(.largeTitle.bold())
            
            Text("You have studied \(currentQuestions.count) questions about \(topic.capitalized)")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Button("Back to Topics") {
                showCompletion = false
                currentIndex = 0
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private func loadQuestionsForTopic() async {
        await questionManager.loadQuestions()
        
        currentQuestions = questionManager.questionsForCategory(topic)
        
        // Fallback in case of mismatch
        if currentQuestions.isEmpty {
            currentQuestions = Array(questionManager.allQuestions.shuffled().prefix(15))
        } else {
            currentQuestions = currentQuestions.shuffled()
        }
        
        currentIndex = 0
    }
    
    private func nextQuestion() {
        if currentIndex < currentQuestions.count - 1 {
            currentIndex += 1
        } else {
            showCompletion = true
        }
    }
}
