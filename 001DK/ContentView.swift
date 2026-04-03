//
//  ContentView.swift
//  001DK
//

import SwiftUI

struct ContentView: View {
    @StateObject private var questionManager = QuestionManager()
    // examType injected via ExamContext environment object
    @StateObject private var navController = NavigationController()
    @StateObject private var scoreStore = ScoreStore()
    @EnvironmentObject private var examContext: ExamContext

    @State private var appeared = false
    @State private var showDisclaimer = false
    @State private var showAbout = false

    var body: some View {
        NavigationStack(path: $navController.path) {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // ── Passport hero card ───────────────────────
                        ZStack(alignment: .topTrailing) {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            examContext.examType.color.opacity(0.88),
                                            examContext.examType.color.opacity(0.6)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: examContext.examType.color.opacity(0.25), radius: 12, y: 6)

                            HStack(spacing: 20) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.white.opacity(0.15))
                                        .frame(width: 72, height: 90)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(.white.opacity(0.3), lineWidth: 1.5)
                                        )

                                    VStack(spacing: 6) {
                                        Image(systemName: "person.crop.rectangle.fill")
                                            .font(.system(size: 28))
                                            .foregroundStyle(.white)
                                        Text("PASSPORT")
                                            .font(.system(size: 7, weight: .bold))
                                            .foregroundStyle(.white.opacity(0.9))
                                            .tracking(1.5)
                                        HStack(spacing: 2) {
                                            ForEach(0..<3) { _ in
                                                Rectangle()
                                                    .fill(.white.opacity(0.5))
                                                    .frame(width: 6, height: 2)
                                            }
                                        }
                                    }
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Your path to\nDanish citizenship")
                                        .font(.title3.bold())
                                        .foregroundStyle(.white)
                                        .lineSpacing(2)

                                    Text("Master \(examContext.examType.displayName)\nwith smart practice")
                                        .font(.footnote)
                                        .foregroundStyle(.white.opacity(0.85))
                                        .lineSpacing(2)

                                    if !questionManager.allQuestions.isEmpty {
                                        HStack(spacing: 6) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.caption)
                                            Text("\(questionManager.allQuestions.count) questions ready")
                                                .font(.caption.bold())
                                        }
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(.white.opacity(0.2))
                                        .cornerRadius(20)
                                    }
                                }

                                Spacer()
                            }
                            .padding(20)

                            // ── Exam switcher pill ───────────────────
                            ExamSwitcherButton()
                                .padding(.top, 14)
                                .padding(.trailing, 16)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(.easeOut(duration: 0.45).delay(0.05), value: appeared)

                        // ── Section label ────────────────────────────
                        HStack {
                            Text("What would you like to do?")
                                .font(.footnote.uppercaseSmallCaps())
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.45).delay(0.15), value: appeared)

                        // ── Action cards ─────────────────────────────
                        VStack(spacing: 12) {
                            Button {
                                navController.path.append(AppRoute.practiceTestStart)
                            } label: {
                                HomeCard(
                                    title: "New Practice Test",
                                    subtitle: "\(examContext.examType.questionCount) questions · \(examContext.examType.minuteCount) minutes, just like the real exam",
                                    icon: "scroll.fill",
                                    color: .blue
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: TopicListView()) {
                                HomeCard(
                                    title: "Study by Topic",
                                    subtitle: "Learn at your own pace, no timer, immediate feedback",
                                    icon: "book.fill",
                                    color: .red
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: ScoreHistoryView()) {
                                HomeCard(
                                    title: "My Scores",
                                    subtitle: "Review past tests and track your progress",
                                    icon: "chart.bar.fill",
                                    color: .green
                                )
                            }
                            .buttonStyle(.plain)

                            Button {
                                showDisclaimer = true
                            } label: {
                                HomeCard(
                                    title: "Disclaimer",
                                    subtitle: "Legal information, copyright & privacy notice",
                                    icon: "doc.text.fill",
                                    color: .gray
                                )
                            }
                            .buttonStyle(.plain)

                            Button {
                                showAbout = true
                            } label: {
                                HomeCard(
                                    title: "About",
                                    subtitle: "App info, developer, version & what's new",
                                    icon: "info.circle.fill",
                                    color: .indigo
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)
                        .animation(.easeOut(duration: 0.5).delay(0.25), value: appeared)

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
                        .padding(.top, 4)
                        .padding(.horizontal, 24)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.35), value: appeared)

                        Spacer(minLength: 40)
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
                await questionManager.switchExam(to: examContext.examType)
            }
            .onChange(of: examContext.examType) { _, newExam in
                Task { await questionManager.switchExam(to: newExam) }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    appeared = true
                }
            }
            .sheet(isPresented: $showDisclaimer) {
                DisclaimerView()
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
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
