//
//  ExamSwitcherButton.swift
//  001DK
//

import SwiftUI

struct ExamSwitcherButton: View {
    @EnvironmentObject private var examContext: ExamContext
    @State private var showSwitcher = false

    var body: some View {
        Button {
            showSwitcher = true
        } label: {
            HStack(spacing: 5) {
                Image(systemName: examContext.examType.icon)
                    .font(.system(size: 11))
                Text(examContext.examType.shortName)
                    .font(.caption.bold())
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(examContext.examType.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(examContext.examType.color.opacity(0.1))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(examContext.examType.color.opacity(0.2), lineWidth: 1))
        }
        .confirmationDialog("Switch Exam", isPresented: $showSwitcher, titleVisibility: .visible) {
            ForEach(ExamType.allCases, id: \.self) { exam in
                Button(exam.displayName) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        examContext.switchExam(to: exam)
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose which exam you are preparing for.")
        }
    }
}
