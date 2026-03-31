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
    let questionNumber: Int

    private var answerBinding: Binding<Int?>?

    init(question: Question,
         showFeedback: Bool = false,
         answerBinding: Binding<Int?>? = nil,
         shuffledChoices: [(originalIndex: Int, text: String)]? = nil,
         questionNumber: Int = 0) {

        self.question = question
        self.showFeedback = showFeedback
        self.answerBinding = answerBinding
        self.questionNumber = questionNumber

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

    // Letter labels for answer choices
    private let choiceLetters = ["A", "B", "C", "D"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // ── Question header ──────────────────────────────────
            HStack(alignment: .top, spacing: 12) {
                // Question number badge
                if viewModel.questionNumber > 0 {
                    Text("\(viewModel.questionNumber)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(Color.blue)
                        .clipShape(Circle())
                }

                Text(viewModel.question.text)
                    .font(.body.weight(.medium))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // ── Answer choices ───────────────────────────────────
            VStack(spacing: 8) {
                ForEach(Array(viewModel.shuffledChoices.enumerated()), id: \.element.originalIndex) { position, item in
                    AnswerButton(
                        text: item.text,
                        letter: choiceLetters[safe: position] ?? "",
                        isSelected: viewModel.selectedIndex == item.originalIndex,
                        showFeedback: viewModel.showFeedback,
                        correctIndex: viewModel.question.correctIndex,
                        selectedIndex: viewModel.selectedIndex,
                        buttonIndex: item.originalIndex
                    )
                    .onTapGesture {
                        viewModel.selectAnswer(at: item.originalIndex)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.07), radius: 6, y: 3)
    }
}

// MARK: - Answer Button
struct AnswerButton: View {
    let text: String
    let letter: String
    let isSelected: Bool
    let showFeedback: Bool
    let correctIndex: Int
    let selectedIndex: Int?
    let buttonIndex: Int

    var body: some View {
        HStack(spacing: 12) {

            // Letter badge
            Text(letter)
                .font(.caption.bold())
                .foregroundStyle(letterTextColor)
                .frame(width: 28, height: 28)
                .background(letterBgColor)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(letterBorderColor, lineWidth: 1.5)
                )

            Text(text)
                .font(.subheadline)
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)

            // Checkmark or X icon when selected
            if isSelected {
                Image(systemName: showFeedback
                      ? (isCorrectAnswer ? "checkmark.circle.fill" : "xmark.circle.fill")
                      : "checkmark.circle.fill")
                    .foregroundStyle(showFeedback
                                     ? (isCorrectAnswer ? .green : .red)
                                     : .blue)
                    .font(.system(size: 18))
                    .transition(.scale.combined(with: .opacity))
            } else if showFeedback && isCorrectAnswer {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 18))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(backgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
        )
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var isCorrectAnswer: Bool { buttonIndex == correctIndex }
    private var isWrongSelected: Bool { isSelected && buttonIndex != correctIndex }

    // MARK: - Background
    private var backgroundColor: Color {
        if showFeedback {
            if isCorrectAnswer { return Color.green.opacity(0.12) }
            if isWrongSelected { return Color.red.opacity(0.12) }
            return Color(.secondarySystemBackground)
        }
        return isSelected ? Color.blue.opacity(0.08) : Color(.secondarySystemBackground)
    }

    // MARK: - Border
    private var borderColor: Color {
        if showFeedback {
            if isCorrectAnswer { return .green }
            if isWrongSelected { return .red }
            return Color(.systemFill)
        }
        return isSelected ? .blue : Color(.systemFill)
    }

    // MARK: - Text
    private var textColor: Color {
        if showFeedback {
            if isCorrectAnswer { return .green }
            if isWrongSelected { return .red }
            return .primary
        }
        return .primary
    }

    // MARK: - Letter badge colors
    private var letterBgColor: Color {
        if showFeedback {
            if isCorrectAnswer { return Color.green.opacity(0.15) }
            if isWrongSelected { return Color.red.opacity(0.15) }
            return Color(.systemFill)
        }
        return isSelected ? Color.blue.opacity(0.15) : Color(.systemFill)
    }

    private var letterBorderColor: Color {
        if showFeedback {
            if isCorrectAnswer { return .green }
            if isWrongSelected { return .red }
            return Color(.systemFill)
        }
        return isSelected ? .blue : Color(.systemFill)
    }

    private var letterTextColor: Color {
        if showFeedback {
            if isCorrectAnswer { return .green }
            if isWrongSelected { return .red }
            return .secondary
        }
        return isSelected ? .blue : .secondary
    }
}

// MARK: - Safe array subscript helper
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
