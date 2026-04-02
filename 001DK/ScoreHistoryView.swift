//
//  ScoreHistoryView.swift
//  001DK
//
//  Created by Aytac Akyildiz on 29/03/2026.
//

import SwiftUI

struct ScoreHistoryView: View {
    @EnvironmentObject private var scoreStore: ScoreStore

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            if scoreStore.results.isEmpty {
                emptyState
            } else {
                resultsList
            }
        }
        .navigationTitle("My Scores")
    }

    // MARK: - Empty state
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No tests yet")
                .font(.title3.bold())
            Text("Complete a practice test and your results will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Results list
    private var resultsList: some View {
        List {
            ForEach(scoreStore.results) { result in
                NavigationLink(destination: ScoreDetailView(result: result)) {
                    ScoreRow(result: result)
                }
                .listRowBackground(Color(.systemBackground))
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            }
            .onDelete { offsets in
                scoreStore.delete(at: offsets)
            }
        }
        .listStyle(.insetGrouped)
        
    }

    // MARK: - Difficulty color helper
    private func difficultyColor(_ difficulty: DifficultyLevel) -> Color {
        switch difficulty {
        case .easy:     return .green
        case .standard: return .blue
        case .hard:     return .red
        }
    }
}

// MARK: - Score Row
struct ScoreRow: View {
    let result: TestResult

    var body: some View {
        HStack(spacing: 14) {

            // Pass/fail indicator
            ZStack {
                Circle()
                    .fill(result.passed ? Color.green.opacity(0.12) : Color.red.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: result.passed ? "checkmark.seal.fill" : "xmark.seal.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(result.passed ? .green : .red)
            }

            VStack(alignment: .leading, spacing: 4) {

                // Score + pass/fail badge
                HStack(spacing: 8) {
                    Text("\(result.score)/\(result.totalQuestions)")
                        .font(.headline)
                        .foregroundStyle(result.passed ? .green : .red)

                    Text(result.passed ? "Passed" : "Failed")
                        .font(.caption.bold())
                        .foregroundStyle(result.passed ? .green : .red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(result.passed
                                    ? Color.green.opacity(0.12)
                                    : Color.red.opacity(0.12))
                        .cornerRadius(6)
                }

                // Date + difficulty on same line
                HStack(spacing: 8) {
                    Text(result.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("·")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: result.difficulty.icon)
                            .font(.caption2)
                        Text(result.difficulty.label)
                            .font(.caption)
                    }
                    .foregroundStyle(difficultyColor(result.difficulty))
                }

                // Values score
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundStyle(result.passedValues ? .green : .red)
                    Text("Values: \(result.valuesScore)/5")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func difficultyColor(_ difficulty: DifficultyLevel) -> Color {
        switch difficulty {
        case .easy:     return .green
        case .standard: return .blue
        case .hard:     return .red
        }
    }
}

// MARK: - Score Detail View
struct ScoreDetailView: View {
    let result: TestResult

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 24) {

                // ── Score card ───────────────────────────────────────
                VStack(spacing: 16) {
                    Text("\(result.score)/\(result.totalQuestions)")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundStyle(result.passed ? .green : .red)

                    Text(result.passed ? "Passed ✓" : "Failed ✗")
                        .font(.title2.bold())
                        .foregroundStyle(result.passed ? .green : .red)

                    Text(result.formattedDate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Difficulty badge
                    HStack(spacing: 6) {
                        Image(systemName: result.difficulty.icon)
                        Text(result.difficulty.label)
                            .font(.caption.bold())
                    }
                    .foregroundStyle(difficultyColor(result.difficulty))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(difficultyColor(result.difficulty).opacity(0.1))
                    .cornerRadius(20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // ── Requirements ─────────────────────────────────────
                VStack(spacing: 10) {
                    RequirementRow(
                        label: "Overall score",
                        detail: "\(result.score)/45 — need 36",
                        passed: result.passedOverall
                    )
                    RequirementRow(
                        label: "Danish Values",
                        detail: "\(result.valuesScore)/5 — need 4",
                        passed: result.passedValues
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(14)
                .padding(.horizontal, 20)

                // ── Wrong answers ────────────────────────────────────
                if result.wrongAnswers.isEmpty {
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
                    .padding(.top, 20)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "list.bullet.clipboard")
                                .foregroundStyle(.red)
                            Text("Review — \(result.wrongAnswers.count) to improve")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.horizontal, 20)

                        ForEach(Array(result.wrongAnswers.enumerated()), id: \.offset) { index, wrong in
                            WrongAnswerCard(index: index + 1, wrong: wrong)
                                .padding(.horizontal, 20)
                        }
                    }
                }

                Spacer(minLength: 40)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Test Detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func difficultyColor(_ difficulty: DifficultyLevel) -> Color {
        switch difficulty {
        case .easy:     return .green
        case .standard: return .blue
        case .hard:     return .red
        }
    }
}

// MARK: - Wrong Answer Card
struct WrongAnswerCard: View {
    let index: Int
    let wrong: WrongAnswer

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
                        .background(wrong.userAnswerIndex == nil ? Color(.systemGray) : Color.red)
                        .clipShape(Circle())

                    Text(wrong.questionText)
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
                    Divider().padding(.horizontal, 14)

                    if let userIndex = wrong.userAnswerIndex {
                        AnswerRow(
                            label: "Your answer",
                            text: wrong.choices[userIndex],
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
                        text: wrong.correctAnswer,
                        color: .green,
                        icon: "checkmark.circle.fill"
                    )

                    if let explanation = wrong.explanation {
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
