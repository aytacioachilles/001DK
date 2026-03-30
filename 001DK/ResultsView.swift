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

    // MARK: - Computed
    var score: Int {
        questions.filter { question in
            if let selected = userAnswers[question.id], selected == question.correctIndex {
                return true
            }
            return false
        }.count
    }

    var passed: Bool { score >= 36 }

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

    // MARK: - Body
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 24) {

                // ── Score card ───────────────────────────────────────
                VStack(spacing: 16) {
                    Text("\(score)/\(questions.count)")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundStyle(passed ? .green : .red)

                    Text(passed ? "You Passed! 🎉" : "Not yet — keep practicing 💪")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    // Stats row
                    HStack(spacing: 0) {
                        StatView(title: "Correct", value: "\(score)", color: .green)
                        Divider().frame(height: 40)
                        StatView(title: "Wrong", value: "\(wrongCount)", color: .red)
                        Divider().frame(height: 40)
                        StatView(title: "Skipped", value: "\(skippedCount)", color: .orange)
                    }
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // ── Pass requirement note ────────────────────────────
                HStack(spacing: 8) {
                    Image(systemName: passed ? "checkmark.seal.fill" : "info.circle.fill")
                        .foregroundStyle(passed ? .green : .blue)
                    Text(passed
                         ? "You met the passing requirement of 36/45."
                         : "You need at least 36 correct answers to pass.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)

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
                    .padding(.top, 20)
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
                }

                // ── Back to Home button ──────────────────────────────
                Button {
                    navController.popToRoot()
                } label: {
                    Text("Back to Home")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Test Results")
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Review Card
struct ReviewCard: View {
    let index: Int
    let question: Question
    let userAnswerIndex: Int?

    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header — always visible
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    // Question number badge
                    Text("\(index)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(userAnswerIndex == nil ? Color.orange : Color.red)
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

            // Expandable detail
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .padding(.horizontal, 14)

                    // User's answer (if they gave one)
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
                            color: .orange,
                            icon: "minus.circle.fill"
                        )
                    }

                    // Correct answer
                    AnswerRow(
                        label: "Correct answer",
                        text: question.correctAnswer,
                        color: .green,
                        icon: "checkmark.circle.fill"
                    )

                    // Explanation — only shown if available
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
