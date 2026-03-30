//
//  StudyQuestionView.swift
//  001DK
//
//  Created by Aytac Akyildiz on 29/03/2026.


import SwiftUI

struct StudyQuestionView: View {
    let topic: String

    @EnvironmentObject private var questionManager: QuestionManager

    @State private var questions: [Question] = []
    @State private var currentIndex = 0
    @State private var selectedIndex: Int? = nil
    @State private var shuffledChoices: [(originalIndex: Int, text: String)] = []
    @State private var isFinished = false

    var currentQuestion: Question? {
        guard !questions.isEmpty, currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var hasAnswered: Bool {
        selectedIndex != nil
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if isFinished {
                finishedView
            } else if let question = currentQuestion {
                VStack(spacing: 0) {

                    // Progress bar
                    VStack(spacing: 6) {
                        HStack {
                            Text("Question \(currentIndex + 1) of \(questions.count)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemFill))
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue)
                                    .frame(width: geo.size.width * CGFloat(currentIndex + 1) / CGFloat(questions.count), height: 6)
                                    .animation(.easeInOut, value: currentIndex)
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                    ScrollView {
                        VStack(spacing: 16) {

                            // Question card
                            VStack(alignment: .leading, spacing: 20) {
                                Text(question.text)
                                    .font(.title3.weight(.medium))
                                    .fixedSize(horizontal: false, vertical: true)

                                // Answer choices
                                VStack(spacing: 10) {
                                    ForEach(shuffledChoices, id: \.originalIndex) { item in
                                        StudyAnswerButton(
                                            text: item.text,
                                            state: buttonState(for: item.originalIndex),
                                            hasAnswered: hasAnswered
                                        )
                                        .onTapGesture {
                                            guard !hasAnswered else { return }
                                            selectedIndex = item.originalIndex
                                        }
                                    }
                                }
                            }
                            .padding(20)
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                            .shadow(radius: 3)
                            .padding(.horizontal, 20)

                            // Explanation card — shown after answering
                            if hasAnswered, let explanation = question.explanation {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundStyle(.yellow)
                                    Text(explanation)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(16)
                                .background(Color.yellow.opacity(0.1))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1.5)
                                )
                                .padding(.horizontal, 20)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }

                            // Next / Finish button — shown after answering
                            if hasAnswered {
                                Button {
                                    goToNext()
                                } label: {
                                    Text(currentIndex + 1 < questions.count ? "Next Question →" : "Finish")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color.blue)
                                        .cornerRadius(14)
                                }
                                .padding(.horizontal, 20)
                                .transition(.opacity)
                            }

                            Spacer(minLength: 40)
                        }
                        .animation(.easeInOut(duration: 0.25), value: hasAnswered)
                    }
                }
            } else {
                ProgressView("Loading questions…")
            }
        }
        .navigationTitle(topicTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadQuestions()
        }
    }

    // MARK: - Finished view
    private var finishedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("Topic Complete!")
                .font(.largeTitle.bold())

            Text("You've gone through all \(questions.count) questions in \(topicTitle).")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)

            NavigationLink(destination: TopicListView()) {
                Text("Back to Topics")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Helpers
    private func buttonState(for originalIndex: Int) -> StudyAnswerState {
        guard let selected = selectedIndex else { return .idle }
        guard let question = currentQuestion else { return .idle }

        if originalIndex == question.correctIndex { return .correct }
        if originalIndex == selected { return .wrong }
        return .idle
    }

    private func goToNext() {
        if currentIndex + 1 < questions.count {
            currentIndex += 1
            selectedIndex = nil
            shuffleCurrentQuestion()
        } else {
            isFinished = true
        }
    }

    private func loadQuestions() {
        let all = questionManager.questionsForCategory(topic)
        questions = Array(all.shuffled().prefix(20))
        selectedIndex = nil
        shuffleCurrentQuestion()
    }

    private func shuffleCurrentQuestion() {
        guard let question = currentQuestion else { return }
        shuffledChoices = question.choices.indices
            .map { (originalIndex: $0, text: question.choices[$0]) }
            .shuffled()
    }

    private var topicTitle: String {
        switch topic {
        case "culture": return "Culture"
        case "history": return "History"
        case "society": return "Society"
        case "values":  return "Values"
        case "recent":  return "Recent Events"
        default:        return topic.capitalized
        }
    }
}

// MARK: - Answer button state
enum StudyAnswerState {
    case idle, correct, wrong
}

// MARK: - Study Answer Button
struct StudyAnswerButton: View {
    let text: String
    let state: StudyAnswerState
    let hasAnswered: Bool

    var body: some View {
        HStack {
            Text(text)
                .font(.body)
                .foregroundStyle(textColor)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            if hasAnswered && state != .idle {
                Image(systemName: state == .correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(state == .correct ? .green : .red)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(backgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.2), value: state)
    }

    private var backgroundColor: Color {
        switch state {
        case .idle:    return Color(.secondarySystemBackground)
        case .correct: return Color.green.opacity(0.15)
        case .wrong:   return Color.red.opacity(0.15)
        }
    }

    private var borderColor: Color {
        switch state {
        case .idle:    return .clear
        case .correct: return .green
        case .wrong:   return .red
        }
    }

    private var textColor: Color {
        switch state {
        case .idle:    return .primary
        case .correct: return .green
        case .wrong:   return .red
        }
    }
}
