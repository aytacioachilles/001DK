//
//  TopicListView.swift
//  001DK
//
//  Created by Aytac Akyildiz on 29/03/2026.
//

import SwiftUI

struct TopicListView: View {
    var body: some View {
        List {
            Section("Study Topics") {
                NavigationLink("Culture") {
                    StudyQuestionView(topic: "culture")
                }
                NavigationLink("History") {
                    StudyQuestionView(topic: "history")
                }
                NavigationLink("Society") {
                    StudyQuestionView(topic: "society")
                }
                NavigationLink("Values") {
                    StudyQuestionView(topic: "values")
                }
                NavigationLink("Recent Events") {
                    StudyQuestionView(topic: "recent")
                }
            }
        }
        .navigationTitle("Study by Topic")
    }
}
