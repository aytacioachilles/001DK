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

    var body: some View {
        ZStack {
            Color(red: 0.78, green: 0.08, blue: 0.12)
                .ignoresSafeArea()

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
                        .foregroundStyle(.white.opacity(0.65))
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
                Button {
                    guard let exam = selectedExam else { return }
                    savedExam = exam.rawValue
                    withAnimation(.easeInOut(duration: 0.4)) {
                        onSelect(exam)
                    }
                } label: {
                    Text(selectedExam == nil ? "Select an exam to continue" : "Continue →")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            selectedExam == nil
                                ? Color.white.opacity(0.2)
                                : Color.white.opacity(0.95)
                        )
                        .foregroundStyle(
                            selectedExam == nil
                                ? Color.white.opacity(0.5)
                                : Color(red: 0.78, green: 0.08, blue: 0.12)
                        )
                        .cornerRadius(16)
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
        HStack(spacing: 16) {

            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.white.opacity(isSelected ? 0.25 : 0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: exam.icon)
                    .font(.system(size: 26))
                    .foregroundStyle(.white)
            }

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(exam.displayName)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(exam.description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
                HStack(spacing: 6) {
                    Image(systemName: "questionmark.circle")
                        .font(.caption)
                    Text("\(exam.questionCount) questions")
                        .font(.caption.bold())
                }
                .foregroundStyle(.white.opacity(0.65))
                .padding(.top, 2)
            }

            Spacer()

            // Selection indicator
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.4), lineWidth: 2)
                    .frame(width: 26, height: 26)
                if isSelected {
                    Circle()
                        .fill(.white)
                        .frame(width: 26, height: 26)
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(red: 0.78, green: 0.08, blue: 0.12))
                }
            }
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white.opacity(isSelected ? 0.18 : 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(isSelected ? 0.6 : 0.2), lineWidth: isSelected ? 2 : 1)
                )
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
