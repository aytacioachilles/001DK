//
//  TopicListView.swift
//  001DK
//
//  Created by Aytac Akyildiz on 29/03/2026.
//

import SwiftUI

struct TopicListView: View {

    let topics: [(title: String, subtitle: String, topic: String, icon: String, color: Color)] = [
        ("Culture",       "Art, music, literature, movies & traditions",                "culture", "🎭", .purple),
        ("History",       "From great Vikings to today's modern Denmark",               "history", "⚔️", .brown),
        ("Society",       "Government, institutions, politics, welfare & daily life",   "society", "🏛️", .blue),
        ("Values",        "Danish values & the Grundlov",                               "values",  "❤️", .red),
        ("Recent Events", "Events that took place in Denmark recently",                 "recent",  "📰", .orange),
    ]

    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(Array(topics.enumerated()), id: \.element.topic) { index, item in
                    NavigationLink(destination: StudyQuestionView(topic: item.topic)) {
                        TopicCard(item: item)
                    }
                    .buttonStyle(.plain)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .animation(
                        .easeOut(duration: 0.4).delay(Double(index) * 0.07),
                        value: appeared
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Study by Topic")
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                appeared = true
            }
        }
    }
}

// MARK: - Topic Card
struct TopicCard: View {
    let item: (title: String, subtitle: String, topic: String, icon: String, color: Color)

    var body: some View {
        HStack(spacing: 16) {

            // Icon bubble
            Text(item.icon)
                .font(.system(size: 28))
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        colors: [item.color.opacity(0.18), item.color.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(item.color.opacity(0.2), lineWidth: 1.5)
                )

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(item.color.opacity(0.5))
                .padding(8)
                .background(item.color.opacity(0.08))
                .clipShape(Circle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: item.color.opacity(0.1), radius: 8, y: 3)
    }
}

