//
//  TopicListView.swift
//  001DK
//
//  Created by Aytac Akyildiz on 29/03/2026.
//

//
//  TopicListView.swift
//  borgerDk
//

import SwiftUI

struct TopicListView: View {
    
    let topics: [(title: String, subtitle: String, topic: String, icon: String, color: Color)] = [
        ("Culture",        "Art, music, literature, movies & traditions",  "culture",  "🎭", .purple),
        ("History",        "From great Vikings to today's modern Denmark",        "history",  "⚔️", .brown),
        ("Society",        "Government, institutions, politics, welfare & daily life",      "society",  "🏛️", .blue),
        ("Values",         "Danish values & the Grundlov",          "values",   "❤️", .red),
        ("Recent Events",  "Events that took place in Denmark recently",              "recent",   "📰", .orange),
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(topics, id: \.topic) { item in
                    NavigationLink(destination: StudyQuestionView(topic: item.topic)) {
                        TopicCard(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Study by Topic")
    }
}

struct TopicCard: View {
    let item: (title: String, subtitle: String, topic: String, icon: String, color: Color)
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon bubble
            Text(item.icon)
                .font(.system(size: 30))
                .frame(width: 58, height: 58)
                .background(item.color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(item.color.opacity(0.25), lineWidth: 1.5)
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
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.subheadline.bold())
                .foregroundStyle(item.color.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: item.color.opacity(0.08), radius: 6, y: 3)
    }
}
