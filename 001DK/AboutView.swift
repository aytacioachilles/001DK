//
//  AboutView.swift
//  001DK
//
//  Created by Aytac Akyildiz on 31/03/2026.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // ── App identity ─────────────────────────────────
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.red.opacity(0.85), Color.red.opacity(0.55)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            Image(systemName: "flag.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.white)
                        }
                        .shadow(color: .red.opacity(0.3), radius: 8, y: 4)

                        Text("Your Path to Danish Citizenship")
                            .font(.title3.bold())

                        Text("Indfødsretsprøven")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        // Version pill
                        HStack(spacing: 6) {
                            Image(systemName: "app.badge.fill")
                                .font(.caption)
                            Text("Version \(appVersion) (\(buildNumber))")
                                .font(.caption.bold())
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemFill))
                        .cornerRadius(20)
                    }
                    .padding(.top, 16)

                    // ── About section ────────────────────────────────
                    AboutSection(title: "About This App") {
                        AboutRow(
                            icon: "text.book.closed.fill",
                            iconColor: .blue,
                            title: "Purpose",
                            value: "[PLACEHOLDER: Brief description of the app and its mission — e.g. 'Helping people in Denmark prepare for the citizenship test through smart, structured practice.']"
                        )
                        Divider().padding(.horizontal, 14)
                        AboutRow(
                            icon: "person.fill",
                            iconColor: .indigo,
                            title: "Developer",
                            value: "[PLACEHOLDER: Your name or company name]"
                        )
                        Divider().padding(.horizontal, 14)
                        AboutRow(
                            icon: "building.2.fill",
                            iconColor: .purple,
                            title: "Company",
                            value: "[PLACEHOLDER: Company name or 'Independent Developer']"
                        )
                        Divider().padding(.horizontal, 14)
                        AboutRow(
                            icon: "envelope.fill",
                            iconColor: .green,
                            title: "Contact",
                            value: "[PLACEHOLDER: contact@yourdomain.com]"
                        )
                        Divider().padding(.horizontal, 14)
                        AboutRow(
                            icon: "globe",
                            iconColor: .blue,
                            title: "Website",
                            value: "[PLACEHOLDER: https://yourwebsite.com]"
                        )
                    }

                    // ── What's New ───────────────────────────────────
                    AboutSection(title: "What's New") {
                        WhatsNewRow(
                            version: "1.0.0",
                            date: "[RELEASE DATE]",
                            items: [
                                "Initial release",
                                "Practice tests with 45 questions",
                                "Study by topic mode",
                                "Score history with detailed review",
                                "Easy / Standard / Hard difficulty levels",
                                "Offline support with cached questions"
                            ]
                        )
                    }

                    // ── Acknowledgements ─────────────────────────────
                    AboutSection(title: "Acknowledgements") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("[PLACEHOLDER: Any acknowledgements, data sources, open source libraries used, or individuals you want to thank.]")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(14)
                        }
                    }

                    // ── Footer ───────────────────────────────────────
                    Text("© [YEAR] [COMPANY NAME]. All rights reserved.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - About Section container
struct AboutSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.footnote.uppercaseSmallCaps())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content
            }
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
    }
}

// MARK: - About Row
struct AboutRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.subheadline)
                .frame(width: 28)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - What's New Row
struct WhatsNewRow: View {
    let version: String
    let date: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Version \(version)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                Spacer()
                Text(date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                            .padding(.top, 2)
                        Text(item)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(14)
    }
}
