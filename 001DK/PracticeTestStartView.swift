//
//  PracticeTestStartView.swift
//  001DK
//
//  Created by Aytac Akyildiz on 29/03/2026.
//

import SwiftUI

struct PracticeTestStartView: View {
    @EnvironmentObject private var navController: NavigationController
    @EnvironmentObject private var examContext: ExamContext
    
    @State private var selectedDifficulty: DifficultyLevel = .standard

    var body: some View {
        VStack(spacing: 0) {

            // ── Icon & title ─────────────────────────────────────
            VStack(spacing: 8) {
                Image(systemName: "scroll.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.blue)

                Text("Practice Test")
                    .font(.title2.bold())

                Text("\(examContext.examType.questionCount) questions · \(examContext.examType.minuteCount) minutes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)

            Spacer()

            // ── Difficulty selector ──────────────────────────────
            VStack(alignment: .leading, spacing: 10) {
                Text("Select Difficulty")
                    .font(.subheadline.uppercaseSmallCaps().weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)

                VStack(spacing: 8) {
                    ForEach(DifficultyLevel.allCases, id: \.self) { level in
                        DifficultyCard(
                            level: level,
                            isSelected: selectedDifficulty == level
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDifficulty = level
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // ── AI questions note ────────────────────────────────
            if selectedDifficulty != .easy {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.subheadline)
                    Text(selectedDifficulty == .standard
                         ? "Standard mode includes ~30% AI-generated questions mixed with previous exam questions."
                         : "Hard mode includes ~50% AI-generated questions. Ideal for advanced preparation.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(Color.blue.opacity(0.07))
                .cornerRadius(12)
                .padding(.horizontal, 24)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Spacer()

            // ── Bottom section ───────────────────────────────────
            VStack(spacing: 12) {
                Button {
                    navController.selectedDifficulty = selectedDifficulty
                    navController.path.append(AppRoute.practiceTest)
                } label: {
                    Text("Start \(selectedDifficulty.label) Test")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(difficultyColor)
                        .cornerRadius(16)
                        .shadow(color: difficultyColor.opacity(0.35), radius: 8, y: 4)
                }

                Text("You can skip questions, go back, and change answers during the test")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("New Practice Test")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.2), value: selectedDifficulty)
    }

    private var difficultyColor: Color {
        switch selectedDifficulty {
        case .easy:     return .green
        case .standard: return .blue
        case .hard:     return .red
        }
    }
}

// MARK: - Difficulty Card
struct DifficultyCard: View {
    let level: DifficultyLevel
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: level.icon)
                .font(.title3)
                .foregroundStyle(cardColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(level.label)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                Text(level.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(cardColor)
                    .font(.title3)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            isSelected
                ? cardColor.opacity(0.08)
                : Color(.systemBackground)
        )
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? cardColor : Color.clear, lineWidth: 2)
        )
        .shadow(
            color: isSelected ? cardColor.opacity(0.12) : Color.black.opacity(0.04),
            radius: 4, y: 2
        )
    }

    private var cardColor: Color {
        switch level {
        case .easy:     return .green
        case .standard: return .blue
        case .hard:     return .red
        }
    }
}

