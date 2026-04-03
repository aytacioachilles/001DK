//
//  ExamPickerView.swift
//  001DK
//

import SwiftUI

struct ExamPickerView: View {
    @AppStorage("selectedExamType") private var savedExam: String = ""
    var onSelect: (ExamType) -> Void

    @State private var appeared = false
    @State private var selectedExam: ExamType? = nil

    private let darkRed = Color(red: 0.78, green: 0.08, blue: 0.12)

    var body: some View {
        ZStack {
            darkRed.ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Header ───────────────────────────────────────────
                VStack(spacing: 12) {
                    DannebrogView()
                        .frame(width: 72, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Text("Which exam are\nyou preparing for?")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)

                    Text("You can change this later from the home screen.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 72)
                .padding(.horizontal, 32)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.easeOut(duration: 0.45).delay(0.05), value: appeared)

                Spacer()

                // ── Exam cards ────────────────────────────────────────
                VStack(spacing: 14) {
                    ForEach(ExamType.allCases, id: \.self) { exam in
                        ExamCard(
                            exam: exam,
                            isSelected: selectedExam == exam
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedExam = exam
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.15), value: appeared)

                Spacer()

                // ── Continue button ───────────────────────────────────
                // Fix #4: restructure so foregroundStyle switches correctly
                Button {
                    guard let exam = selectedExam else { return }
                    savedExam = exam.rawValue
                    withAnimation(.easeInOut(duration: 0.4)) {
                        onSelect(exam)
                    }
                } label: {
                    Text(selectedExam == nil ? "Select an exam to continue" : "Continue →")
                        .font(.headline)
                        .foregroundStyle(
                            selectedExam == nil
                                ? Color.white.opacity(0.55)
                                : darkRed
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            selectedExam == nil
                                ? Color.white.opacity(0.18)
                                : Color.white
                        )
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(selectedExam == nil ? 0.3 : 0), lineWidth: 1)
                        )
                }
                .disabled(selectedExam == nil)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.25), value: appeared)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                appeared = true
            }
        }
    }
}

// MARK: - Exam Card
struct ExamCard: View {
    let exam: ExamType
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {

            // Icon — fix #1: stronger white fill for better contrast
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isSelected ? 0.30 : 0.18))
                    .frame(width: 52, height: 52)
                Image(systemName: exam.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
            }

            // Text — fix #2: smaller font + single line scaling
            VStack(alignment: .leading, spacing: 5) {
                Text(exam.displayName)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(exam.description)
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.85))
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "questionmark.circle")
                        .font(.caption2)
                    Text("\(exam.questionCount) questions  \(exam.minuteCount) minutes" )
                        .font(.caption2.bold())
                }
                .foregroundStyle(Color.white.opacity(0.75))
                .padding(.top, 1)
            }

            Spacer()

            // Selection indicator — fix #1: brighter ring when unselected
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(isSelected ? 0 : 0.6), lineWidth: 2)
                    .frame(width: 26, height: 26)
                if isSelected {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(red: 0.78, green: 0.08, blue: 0.12))
                }
            }
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        // fix #1: stronger card background + border contrast
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(isSelected ? 0.22 : 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            Color.white.opacity(isSelected ? 0.8 : 0.4),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
