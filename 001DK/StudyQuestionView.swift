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
    @State private var cardAppeared = false
    @State private var correctCount = 0

    // Letter labels
    private let choiceLetters = ["A", "B", "C", "D"]

    var currentQuestion: Question? {
        guard !questions.isEmpty, currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var hasAnswered: Bool { selectedIndex != nil }

    var progressValue: CGFloat {
        guard questions.count > 0 else { return 0 }
        return CGFloat(currentIndex + 1) / CGFloat(questions.count)
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            if isFinished {
                finishedView
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity
                    ))
            } else if let question = currentQuestion {
                VStack(spacing: 0) {

                    // ── Header ───────────────────────────────────────
                    VStack(spacing: 10) {
                        HStack {
                            // Question counter badge
                            Text("\(currentIndex + 1) / \(questions.count)")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue)
                                .cornerRadius(20)

                            Spacer()

                            // Correct counter
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                                Text("\(correctCount) correct")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(20)
                        }

                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemFill))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .blue.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * progressValue, height: 6)
                                    .animation(.easeInOut(duration: 0.4), value: currentIndex)
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 16)

                    ScrollView {
                        VStack(spacing: 14) {

                            // ── Question card ────────────────────────
                            VStack(alignment: .leading, spacing: 16) {

                                // Source badge
                                if question.isAI {
                                    HStack(spacing: 5) {
                                        Image(systemName: "sparkles")
                                            .font(.caption2)
                                        Text("AI Generated")
                                            .font(.caption.bold())
                                    }
                                    .foregroundStyle(.purple)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.purple.opacity(0.1))
                                    .cornerRadius(8)
                                }

                                Text(question.text)
                                    .font(.body.weight(.medium))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineSpacing(3)

                                // Answer choices
                                VStack(spacing: 8) {
                                    ForEach(Array(shuffledChoices.enumerated()), id: \.element.originalIndex) { position, item in
                                        StudyAnswerButton(
                                            text: item.text,
                                            letter: choiceLetters[safe: position] ?? "",
                                            state: buttonState(for: item.originalIndex),
                                            hasAnswered: hasAnswered
                                        )
                                        .onTapGesture {
                                            guard !hasAnswered else { return }
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedIndex = item.originalIndex
                                                if item.originalIndex == question.correctIndex {
                                                    correctCount += 1
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(20)
                            .background(Color(.systemBackground))
                            .cornerRadius(18)
                            .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
                            .padding(.horizontal, 20)
                            .opacity(cardAppeared ? 1 : 0)
                            .offset(y: cardAppeared ? 0 : 16)
                            .animation(.easeOut(duration: 0.35), value: cardAppeared)

                            // ── Result banner ────────────────────────
                            if hasAnswered {
                                let isCorrect = selectedIndex == question.correctIndex
                                HStack(spacing: 12) {
                                    Image(systemName: isCorrect
                                          ? "checkmark.circle.fill"
                                          : "xmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(isCorrect ? .green : .red)

                                    Text(isCorrect ? "Correct! Well done." : "Incorrect — check the answer above.")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(isCorrect ? .green : .red)

                                    Spacer()
                                }
                                .padding(14)
                                .background(isCorrect
                                             ? Color.green.opacity(0.1)
                                             : Color.red.opacity(0.1))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(
                                            isCorrect ? Color.green.opacity(0.3) : Color.red.opacity(0.3),
                                            lineWidth: 1.5
                                        )
                                )
                                .padding(.horizontal, 20)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }

                            // ── Explanation ──────────────────────────
                            if hasAnswered, let explanation = question.explanation {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundStyle(.yellow)
                                        .font(.subheadline)
                                    Text(explanation)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(16)
                                .background(Color.yellow.opacity(0.08))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1.5)
                                )
                                .padding(.horizontal, 20)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }

                            // ── Next button ──────────────────────────
                            if hasAnswered {
                                Button {
                                    goToNext()
                                } label: {
                                    HStack(spacing: 8) {
                                        Text(currentIndex + 1 < questions.count
                                             ? "Next Question"
                                             : "See Results")
                                            .font(.headline)
                                        Image(systemName: currentIndex + 1 < questions.count
                                              ? "arrow.right"
                                              : "checkmark.seal.fill")
                                            .font(.subheadline.bold())
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            colors: [.blue, .blue.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(14)
                                    .shadow(color: .blue.opacity(0.25), radius: 6, y: 3)
                                }
                                .padding(.horizontal, 20)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
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
        .onAppear { loadQuestions() }
    }

    // MARK: - Finished view
    private var finishedView: some View {
        ScrollView {
            VStack(spacing: 24) {

                // Result icon
                ZStack {
                    Circle()
                        .fill(scoreColor.opacity(0.12))
                        .frame(width: 100, height: 100)
                    Image(systemName: scoreSeal)
                        .font(.system(size: 48))
                        .foregroundStyle(scoreColor)
                }
                .padding(.top, 40)

                // Score
                VStack(spacing: 8) {
                    Text("\(correctCount)/\(questions.count)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor)

                    Text(scoreMessage)
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)

                    Text("You've completed all \(questions.count) questions in \(topicTitle).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                // Stats card
                HStack(spacing: 0) {
                    FinishedStat(title: "Correct", value: "\(correctCount)", color: .green)
                    Rectangle()
                        .fill(Color(.systemFill))
                        .frame(width: 1, height: 44)
                    FinishedStat(title: "Wrong", value: "\(questions.count - correctCount)", color: .red)
                    Rectangle()
                        .fill(Color(.systemFill))
                        .frame(width: 1, height: 44)
                    FinishedStat(title: "Total", value: "\(questions.count)", color: .blue)
                }
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
                .padding(.horizontal, 20)

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        restartTopic()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Study Again")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: .blue.opacity(0.25), radius: 6, y: 3)
                    }

                    NavigationLink(destination: TopicListView()) {
                        HStack(spacing: 8) {
                            Image(systemName: "list.bullet")
                            Text("Back to Topics")
                                .font(.headline)
                        }
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue.opacity(0.08))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Score helpers
    private var scoreRatio: Double {
        guard questions.count > 0 else { return 0 }
        return Double(correctCount) / Double(questions.count)
    }

    private var scoreColor: Color {
        if scoreRatio >= 0.8 { return .green }
        if scoreRatio >= 0.5 { return .orange }
        return .red
    }

    private var scoreSeal: String {
        if scoreRatio >= 0.8 { return "checkmark.seal.fill" }
        if scoreRatio >= 0.5 { return "exclamationmark.circle.fill" }
        return "xmark.circle.fill"
    }

    private var scoreMessage: String {
        if scoreRatio >= 0.8 { return "Excellent work! 🎉" }
        if scoreRatio >= 0.5 { return "Good effort — keep going! 💪" }
        return "Keep practicing — you'll get there! 📚"
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
            cardAppeared = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                currentIndex += 1
                selectedIndex = nil
                shuffleCurrentQuestion()
                withAnimation { cardAppeared = true }
            }
        } else {
            withAnimation { isFinished = true }
        }
    }

    private func restartTopic() {
        withAnimation {
            isFinished = false
            correctCount = 0
            currentIndex = 0
            selectedIndex = nil
            loadQuestions()
            cardAppeared = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation { cardAppeared = true }
            }
        }
    }

    private func loadQuestions() {
        let all = questionManager.questionsForCategory(topic)
        questions = Array(all.shuffled().prefix(20))
        selectedIndex = nil
        shuffleCurrentQuestion()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation { cardAppeared = true }
        }
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
    let letter: String
    let state: StudyAnswerState
    let hasAnswered: Bool

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
                    Circle().stroke(letterBorderColor, lineWidth: 1.5)
                )

            Text(text)
                .font(.subheadline)
                .foregroundStyle(textColor)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            if hasAnswered && state != .idle {
                Image(systemName: state == .correct
                      ? "checkmark.circle.fill"
                      : "xmark.circle.fill")
                    .foregroundStyle(state == .correct ? .green : .red)
                    .font(.system(size: 18))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(backgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: state == .idle ? 1 : 2)
        )
        .animation(.easeInOut(duration: 0.2), value: state)
    }

    private var backgroundColor: Color {
        switch state {
        case .idle:    return Color(.secondarySystemBackground)
        case .correct: return Color.green.opacity(0.12)
        case .wrong:   return Color.red.opacity(0.12)
        }
    }

    private var borderColor: Color {
        switch state {
        case .idle:    return Color(.systemFill)
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

    private var letterBgColor: Color {
        switch state {
        case .idle:    return Color(.systemFill)
        case .correct: return Color.green.opacity(0.15)
        case .wrong:   return Color.red.opacity(0.15)
        }
    }

    private var letterBorderColor: Color {
        switch state {
        case .idle:    return Color(.systemFill)
        case .correct: return .green
        case .wrong:   return .red
        }
    }

    private var letterTextColor: Color {
        switch state {
        case .idle:    return .secondary
        case .correct: return .green
        case .wrong:   return .red
        }
    }
}

// MARK: - Finished stat view
struct FinishedStat: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Safe subscript
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
