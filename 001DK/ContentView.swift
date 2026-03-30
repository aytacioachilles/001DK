//
//  ContentView.swift
//  001DK
//
//  Created by Aytac Akyildiz on 29/03/2026.
//

//
//  ContentView.swift
//  borgerDk
//
import SwiftUI

struct ContentView: View {
    @StateObject private var questionManager = QuestionManager()
    @StateObject private var navController = NavigationController()
    @StateObject private var scoreStore = ScoreStore()

    var body: some View {
        NavigationStack(path: $navController.path) {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    // ── Header ──────────────────────────────────────────
                    ZStack {
                        Color.red
                            .ignoresSafeArea(edges: .top)

                        VStack(spacing: 10) {
                            HStack(spacing: 14) {
                                // Danish cross flag feel
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 64, height: 64)
                                    Image(systemName: "flag.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(.white)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Danish Citizenship")
                                        .font(.title2.bold())
                                        .foregroundStyle(.white)
                                    Text("Indfødsretsprøven Prep")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.85))
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            .padding(.bottom, 24)
                        }
                    }
                    .frame(height: 130)

                    // ── Body ─────────────────────────────────────────────
                    ScrollView {
                        VStack(spacing: 12) {

                            // Section label
                            HStack {
                                Text("What would you like to do?")
                                    .font(.footnote.uppercaseSmallCaps())
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            .padding(.bottom, 4)

                            // Practice Test button
                            Button {
                                navController.path.append(AppRoute.practiceTestStart)
                            } label: {
                                HomeCard(
                                    title: "New Practice Test",
                                    subtitle: "45 questions · 45 minutes, just like the real exam",
                                    icon: "scroll.fill",
                                    color: .blue
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)

                            // Study by Topic
                            NavigationLink(destination: TopicListView()) {
                                HomeCard(
                                    title: "Study by Topic",
                                    subtitle: "Learn at your own pace, no timer, immediate feedback",
                                    icon: "book.fill",
                                    color: .red
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)

                            // My Scores
                            NavigationLink(destination: ScoreHistoryView()) {
                                HomeCard(
                                    title: "My Scores",
                                    subtitle: "Review past tests and track your progress",
                                    icon: "chart.bar.fill",
                                    color: .yellow
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)

                            // ── Status message ───────────────────────────
                            Group {
                                if questionManager.isLoading {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                        Text("Downloading latest questions…")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                } else if let error = questionManager.lastError {
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(.red)
                                        Text(error)
                                            .font(.footnote)
                                            .foregroundStyle(.red)
                                    }
                                } else if questionManager.usingCachedData {
                                    HStack(spacing: 8) {
                                        Image(systemName: "wifi.slash")
                                            .foregroundStyle(.orange)
                                        Text("No internet — using saved questions")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                } else if questionManager.allQuestions.isEmpty {
                                    Text("No questions loaded yet")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.top, 8)
                            .padding(.horizontal, 24)

                            Spacer(minLength: 40)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .practiceTestStart:
                    PracticeTestStartView()
                case .practiceTest:
                    PracticeTestView()
                case .results:
                    ResultsView(
                        questions: navController.testQuestions,
                        userAnswers: navController.userAnswers
                    )
                }
            }
            .task {
                await questionManager.loadQuestions()
            }
        }
        .environmentObject(questionManager)
        .environmentObject(navController)
        .environmentObject(scoreStore)
    }
}

// MARK: - Home Card
struct HomeCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            // Icon bubble
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)
                .frame(width: 52, height: 52)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(color.opacity(0.2), lineWidth: 1.5)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline.bold())
                .foregroundStyle(color.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: color.opacity(0.08), radius: 6, y: 3)
    }
}
