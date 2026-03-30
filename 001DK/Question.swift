//
//  Question.swift
//  001DK
//
//  Created by Aytac Akyildiz on 29/03/2026.
//


import SwiftUI
import Combine

// MARK: - QuestionViewModel
class QuestionViewModel: ObservableObject {
    
    @Published var selectedIndex: Int? = nil
    
    let question: Question
    let showFeedback: Bool
    let shuffledChoices: [(originalIndex: Int, text: String)]
    
    private var answerBinding: Binding<Int?>?
    
    init(question: Question,
         showFeedback: Bool = false,
         answerBinding: Binding<Int?>? = nil,
         shuffledChoices: [(originalIndex: Int, text: String)]? = nil) {
        
        self.question = question
        self.showFeedback = showFeedback
        self.answerBinding = answerBinding
        
        if let preShuffled = shuffledChoices {
            self.shuffledChoices = preShuffled
        } else {
            _ = Array(0..<question.choices.count)
            let shuffled = question.choices.indices
                .map { (originalIndex: $0, text: question.choices[$0]) }
                .shuffled()
            self.shuffledChoices = shuffled
        }
        
        if let binding = answerBinding, let saved = binding.wrappedValue {
            self.selectedIndex = saved
        }
    }
    
    func selectAnswer(at index: Int) {
        selectedIndex = index
        answerBinding?.wrappedValue = index
    }
}

// MARK: - Reusable Question View
struct QuestionView: View {
    @ObservedObject var viewModel: QuestionViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(viewModel.question.text)
                .font(.title3)
                .fontWeight(.medium)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 0)
            
            VStack(spacing: 10) {
                ForEach(viewModel.shuffledChoices, id: \.originalIndex) { item in
                    AnswerButton(
                        text: item.text,
                        isSelected: viewModel.selectedIndex == item.originalIndex,
                        showFeedback: viewModel.showFeedback,
                        correctIndex: viewModel.question.correctIndex,      // kept your original name
                        selectedIndex: viewModel.selectedIndex,
                        buttonIndex: item.originalIndex                     // kept your original name
                    )
                    .onTapGesture {
                        viewModel.selectAnswer(at: item.originalIndex)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(radius: 3)
    }
}

// MARK: - Answer Button (Logic Fixed - UI unchanged)
struct AnswerButton: View {
    let text: String
    let isSelected: Bool
    let showFeedback: Bool
    let correctIndex: Int
    let selectedIndex: Int?
    let buttonIndex: Int
        
    var body: some View {
        HStack(alignment: .top) {
            Text(text)
                .font(.body)
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .background(backgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 2)
        )
    }
    
    private var isCorrectAnswer: Bool { buttonIndex == correctIndex }
    private var isWrongSelected: Bool { isSelected && buttonIndex != correctIndex }
    
    private var backgroundColor: Color {
        if showFeedback {
            if isCorrectAnswer { return Color.green.opacity(0.25) }
            if isWrongSelected { return Color.red.opacity(0.25) }
            return Color(.secondarySystemBackground)
        }
        return isSelected ? Color.blue.opacity(0.15) : Color(.secondarySystemBackground)
    }
    
    private var borderColor: Color {
        if showFeedback {
            if isCorrectAnswer { return .green }
            if isWrongSelected { return .red }
            return .clear
        }
        return isSelected ? .blue : .clear
    }
    
    private var textColor: Color {
        if showFeedback {
            if isCorrectAnswer { return .green }
            if isWrongSelected { return .red }
            return .primary
        }
        return .primary
    }
}
