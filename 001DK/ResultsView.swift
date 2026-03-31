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
    @EnvironmentObject private var scoreStore: ScoreStore

    @State private var alreadySaved = false
    @State private var appeared = false

    // MARK: - Computed
    var score: Int {
        questions.filter { question in
            if let selected = userAnswers[question.id], selected == question.correctIndex {
                return true
            }
            return false
        }.count
    }

    var valuesQuestions: [Question] {
        questions.filter { $0.category == "values" }
    }

    var valuesScore: Int {
        valuesQuestions.filter { question in
            if let selected = userAnswers[question.id], selected == question.correctIndex {
                return true
            }
            return false
        }.count
    }

    var passedOverall: Bool { score >= 36 }
    var passedValues: Bool { valuesScore >= 4 }
    var passed: Bool { passedOverall && passedValues }

    var wrongQuestions: [(question: Question, userAnswerIndex: Int?)] {
        questions.compactMap { question in
            let selected = userAnswers[question.id] ?? nil
            if selected != question.correctIndex {
                return (question: question, userAnswerIndex: selected)
            }
            return nil
        }
    }

    var skippedCount: Int {
        wrongQuestions.filter { $0.userAnswerIndex == nil }.count
    }

    var wrongCount: Int {
        wrongQuestions.filter { $0.userAnswerIndex != nil }.count
    }

    private var difficultyColor: Color {
        switch navController.selectedDifficulty {
        case .easy:     return .green
        case .standard: return .blue
        case .hard:     return .red
        }
    }

    private var scoreColor: Color { passed ? .green : .red }

    // MARK: - Body
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 20) {

                // ── Hero score card ──────────────────────────────────
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: passed
                                    ? [Color.green.opacity(0.85), Color.green.opacity(0.55)]
                                    : [Color.red.opacity(0.85), Color.red.opacity(0.55)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: scoreColor.opacity(0.3), radius: 16, y: 8)

                    VStack(spacing: 14) {

                        // Pass/fail icon
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.2))
                                .frame(width: 72, height: 72)
                            Image(systemName: passed
                                  ? "checkmark.seal.fill"
                                  : "xmark.seal.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.white)
                        }
                        .scaleEffect(appeared ? 1 : 0.5)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1),
                                   value: appeared)

                        // Score number
                        Text("\(score)/\(questions.count)")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 10)
                            .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)

                        // Pass/fail message
                        Text(passed ? "You Passed! 🎉" : "Not yet — keep practicing 😔")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)

                        // Difficulty badge
                        HStack(spacing: 6) {
                            Image(systemName: navController.selectedDifficulty.icon)
                            Text(navController.selectedDifficulty.label)
                                .font(.caption.bold())
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.2))
                        .cornerRadius(20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.35), value: appeared)
                    }
                    .padding(.vertical, 28)
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // ── Stats row ────────────────────────────────────────
                HStack(spacing: 0) {
                    StatView(title: "Correct", value: "\(score)", color: .green)

                    Rectangle()
                        .fill(Color(.systemFill))
                        .frame(width: 1, height: 44)

                    StatView(title: "Wrong", value: "\(wrongCount)", color: .red)

                    Rectangle()
                        .fill(Color(.systemFill))
                        .frame(width: 1, height: 44)

                    StatView(title: "Skipped", value: "\(skippedCount)", color: Color(.systemGray))
                }
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
                .padding(.horizontal, 20)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.4), value: appeared)

                // ── Pass requirements breakdown ──────────────────────
                VStack(spacing: 0) {
                    RequirementRow(
                        label: "Overall score",
                        detail: "\(score)/45 — need 36",
                        passed: passedOverall
                    )
                    Divider().padding(.horizontal, 14)
                    RequirementRow(
                        label: "Danish Values",
                        detail: "\(valuesScore)/5 — need 4",
                        passed: passedValues
                    )
                }
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
                .padding(.horizontal, 20)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.45), value: appeared)

                // ── Failure reason if failed ─────────────────────────
                if !passed {
                    VStack(alignment: .leading, spacing: 8) {
                        if !passedOverall {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text("\(36 - score) / 45 correct answer\(36 - score == 1 ? "" : "s") needed overall.")
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                            }
                        }
                        if !passedValues {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text("\(4 - valuesScore) / 5 correct Danish Values answer\(4 - valuesScore == 1 ? "" : "s") needed.")
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.red.opacity(0.06))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.5), value: appeared)
                }

                // ── Review section ───────────────────────────────────
                if wrongQuestions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.yellow)
                        Text("Perfect score!")
                            .font(.title3.bold())
                        Text("You answered every question correctly.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 10)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.5), value: appeared)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "list.bullet.clipboard")
                                .foregroundStyle(.red)
                            Text("Review — \(wrongQuestions.count) to improve")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.horizontal, 20)

                        ForEach(Array(wrongQuestions.enumerated()), id: \.offset) { index, item in
                            ReviewCard(
                                index: index + 1,
                                question: item.question,
                                userAnswerIndex: item.userAnswerIndex
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.easeOut(duration: 0.4).delay(0.5), value: appeared)
                }

                // ── Return Home button ───────────────────────────────
                Button {
                    navController.popToRoot()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "house.fill")
                        Text("Home")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.55), value: appeared)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Test Results")
        .navigationBarBackButtonHidden(true)
        .onAppear {
            saveResult()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                appeared = true
            }
        }
    }

    // MARK: - Save result
    private func saveResult() {
        guard !alreadySaved else { return }
        alreadySaved = true

        let wrong = wrongQuestions.map { item in
            WrongAnswer(
                id: item.question.id,
                questionText: item.question.text,
                choices: item.question.choices,
                correctIndex: item.question.correctIndex,
                userAnswerIndex: item.userAnswerIndex,
                explanation: item.question.explanation,
                category: item.question.category
            )
        }

        let result = TestResult(
            id: UUID(),
            date: Date(),
            score: score,
            totalQuestions: questions.count,
            valuesScore: valuesScore,
            passedOverall: passedOverall,
            passedValues: passedValues,
            wrongAnswers: wrong,
            difficulty: navController.selectedDifficulty
        )

        scoreStore.save(result: result)
    }
}

// MARK: - Requirement Row
struct RequirementRow: View {
    let label: String
    let detail: String
    let passed: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(passed ? .green : .red)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(passed ? "✓ Pass" : "✗ Fail")
                .font(.caption.bold())
                .foregroundStyle(passed ? .green : .red)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(passed ? Color.green.opacity(0.12) : Color.red.opacity(0.12))
                .cornerRadius(8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Review Card
struct ReviewCard: View {
    let index: Int
    let question: Question
    let userAnswerIndex: Int?

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(userAnswerIndex == nil ? Color(.systemGray) : Color.red)
                        .clipShape(Circle())

                    Text(question.text)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .padding(.horizontal, 14)

                    if let userIndex = userAnswerIndex {
                        AnswerRow(
                            label: "Your answer",
                            text: question.choices[userIndex],
                            color: .red,
                            icon: "xmark.circle.fill"
                        )
                    } else {
                        AnswerRow(
                            label: "Your answer",
                            text: "Not answered",
                            color: Color(.systemGray),
                            icon: "minus.circle.fill"
                        )
                    }

                    AnswerRow(
                        label: "Correct answer",
                        text: question.correctAnswer,
                        color: .green,
                        icon: "checkmark.circle.fill"
                    )

                    if let explanation = question.explanation {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                                .font(.subheadline)
                            Text(explanation)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 14)
                        .padding(.bottom, 4)
                    }
                }
                .padding(.bottom, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}

// MARK: - Answer Row
struct AnswerRow: View {
    let label: String
    let text: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.subheadline)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 14)
    }
}

// MARK: - Stat View
struct StatView: View {
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
