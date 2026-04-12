//
//  DisclaimerView.swift
//  001DK
//
//  Created by Aytac Akyildiz on 31/03/2026.
//

import SwiftUI

struct DisclaimerView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // ── Header icon ──────────────────────────────────
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 72, height: 72)
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.gray)
                        }
                        Spacer()
                    }
                    .padding(.top, 8)

                    // ── Sections ─────────────────────────────────────
                    DisclaimerSection(
                        icon: "books.vertical.fill",
                        iconColor: .blue,
                        title: "Educational Purpose",
                        content: "This application is developed solely for educational purposes to help individuals prepare for the Danish permanent residency test (Medborgerskabsprøven) and citizenship test (Indfødsretsprøven). The content provided is intended as a study aid and does not constitute official examination material."
                    )

                    DisclaimerSection(
                        icon: "c.circle.fill",
                        iconColor: .orange,
                        title: "Copyright Notice",
                        content: "The questions included in this application are based on publicly available questions from previous years' Danish citizenship and permanent residency examinations. No copyright infringement is intended. All original examination materials remain the property of their respective owners. If you believe any content infringes your rights, please contact us."
                    )

                    DisclaimerSection(
                        icon: "person.fill.xmark",
                        iconColor: .green,
                        title: "No Personal Data Collected",
                        content: "This application does not collect, store, or transmit any personal data to external servers. All test results and progress data are stored locally on your device only and are never shared with third parties. No account or registration is required to use this application."
                    )

                    DisclaimerSection(
                        icon: "checkmark.shield.fill",
                        iconColor: .purple,
                        title: "Accuracy Disclaimer",
                        content: "While every effort is made to ensure the accuracy and relevance of the questions and answers provided, this application makes no guarantee that the content reflects the exact format or questions of the current official examination. Always refer to official sources for the most up-to-date examination information."
                    )

                    DisclaimerSection(
                        icon: "arrow.triangle.2.circlepath",
                        iconColor: .red,
                        title: "Content Updates",
                        content: "Question content is updated periodically to reflect recent examination cycles. The application will always attempt to download the latest question bank when an internet connection is available. When offline, previously downloaded questions will be used."
                    )

                    // ── Footer ───────────────────────────────────────
                    Text("Last updated: 01.04.2026")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Disclaimer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Disclaimer Section
struct DisclaimerSection: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.subheadline)
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
            }

            Text(content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}
