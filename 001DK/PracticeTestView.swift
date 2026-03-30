//
//  PracticeTestView.swift
//  001DK
//
//  Created by Aytac Akyildiz on 29/03/2026.


import SwiftUI
import Combine

struct PracticeTestView: View {
    @EnvironmentObject private var questionManager: QuestionManager
    @EnvironmentObject private var navController: NavigationController

    @State private var testQuestions: [Question] = []
    @State private var userAnswers: [String: Int?] = [:]
    @State private var currentPage = 0
    @State private var timeRemaining: TimeInterval = 45 * 60
    @State private var isLoading = true
    @State private var showFinishConfirmation = false
    @State private var showProgressSheet = false

    private let questionsPerPage = 2
    private let timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Computed helpers
    private var totalPages: Int {
        Int(ceil(Double(testQuestions.count) / Double(questionsPerPage)))
    }

    private var answeredCount: Int {
        userAnswers.values.compactMap { $0 }.count
    }

    private var unansweredCount: Int {
        testQuestions.count - answeredCount
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Preparing your practice test...")
            } else {
                mainTestView
            }
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        .task { await startNewTest() }
        .onReceive(timerPublisher) { _ in
            if timeRemaining > 0 { timeRemaining -= 1 } else { finishTest() }
        }
        .alert(
            unansweredCount > 0
                ? "⚠️ \(unansweredCount) Unanswered Question\(unansweredCount == 1 ? "" : "s")"
                : "Finish Test?",
            isPresented: $showFinishConfirmation
        ) {
            Button("Keep Going", role: .cancel) { }
            Button("Finish Test", role: .destructive) { finishTest() }
        } message: {
            Text(unansweredCount > 0
                ? "You still have unanswered questions. Are you sure you want to submit?"
                : "Are you sure you want to submit your answers?")
        }
        .sheet(isPresented: $showProgressSheet) {
            progressSheet
        }
    }

    // MARK: - Main test view
    private var mainTestView: some View {
        VStack(spacing: 0) {

            // Top bar
            HStack(alignment: .center, spacing: 12) {
                Button {
                    showProgressSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "list.bullet.circle")
                            .font(.system(size: 18))
                        Text("\(answeredCount)/\(testQuestions.count)")
                            .font(.subheadline.monospacedDigit())
                    }
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }

                Spacer()

                TimerView(timeRemaining: timeRemaining)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 8)

            // Questions
            TabView(selection: $currentPage) {
                ForEach(0..<totalPages, id: \.self) { page in
                    let pageQuestions = getQuestionsForPage(page)

                    ScrollView(.vertical) {
                        VStack(spacing: 14) {
                            ForEach(pageQuestions) { question in
                                QuestionView(
                                    viewModel: QuestionViewModel(
                                        question: question,
                                        showFeedback: false,
                                        answerBinding: userAnswersBinding(for: question),
                                        shuffledChoices: shuffledChoicesCache[question.id]
                                    )
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, 100)
                    }
                    .tag(page)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Bottom navigation
            HStack(spacing: 20) {
                Button("Previous") {
                    if currentPage > 0 { currentPage -= 1 }
                }
                .disabled(currentPage == 0)
                .buttonStyle(.bordered)

                Spacer()

                Button("Finish Test", role: .destructive) {
                    showFinishConfirmation = true
                }
                .buttonStyle(.borderedProminent)

                Spacer()

                Button("Next") {
                    if currentPage < totalPages - 1 { currentPage += 1 }
                }
                .disabled(currentPage >= totalPages - 1)
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemBackground))
        }
    }

    // MARK: - Progress sheet
    private var progressSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Summary line
                    HStack {
                        Label("\(answeredCount) answered", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Spacer()
                        Label("\(unansweredCount) skipped", systemImage: "circle")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline.bold())
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Dot grid
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 9),
                        spacing: 10
                    ) {
                        ForEach(Array(testQuestions.enumerated()), id: \.offset) { index, question in
                            let isAnswered = userAnswers[question.id] != nil
                            let isCurrentPage = index / questionsPerPage == currentPage

                            Button {
                                currentPage = index / questionsPerPage
                                showProgressSheet = false
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(isAnswered ? Color.blue : Color(.systemFill))
                                        .frame(width: 34, height: 34)
                                        .overlay(
                                            Circle()
                                                .stroke(isCurrentPage ? Color.orange : Color.clear, lineWidth: 2.5)
                                        )
                                    Text("\(index + 1)")
                                        .font(.caption.bold())
                                        .foregroundStyle(isAnswered ? .white : .secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Legend
                    HStack(spacing: 20) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 12, height: 12)
                            Text("Answered")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(.systemFill))
                                .frame(width: 12, height: 12)
                            Text("Skipped")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 6) {
                            Circle()
                                .stroke(Color.orange, lineWidth: 2)
                                .frame(width: 12, height: 12)
                            Text("Current page")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                }
            }
            .navigationTitle("Question Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showProgressSheet = false }
                }
            }
        }
    }

    // MARK: - Helpers
    @State private var shuffledChoicesCache: [String: [(originalIndex: Int, text: String)]] = [:]

    private func startNewTest() async {
        isLoading = true
        await questionManager.loadQuestions()

        testQuestions = questionManager.createPracticeTest()

        shuffledChoicesCache = [:]
        for question in testQuestions {
            shuffledChoicesCache[question.id] = question.choices.indices
                .map { (originalIndex: $0, text: question.choices[$0]) }
                .shuffled()
        }

        userAnswers = [:]
        currentPage = 0
        timeRemaining = 45 * 60
        isLoading = false
    }

    private func getQuestionsForPage(_ page: Int) -> [Question] {
        let start = page * questionsPerPage
        let end = min(start + questionsPerPage, testQuestions.count)
        return Array(testQuestions[start..<end])
    }

    private func userAnswersBinding(for question: Question) -> Binding<Int?> {
        Binding<Int?>(
            get: { userAnswers[question.id] ?? nil },
            set: { userAnswers[question.id] = $0 }
        )
    }

    private func finishTest() {
        navController.testQuestions = testQuestions
        navController.userAnswers = userAnswers
        navController.path.append(AppRoute.results)
    }
}

// MARK: - Timer View
struct TimerView: View {
    let timeRemaining: TimeInterval
    var body: some View {
        Text(String(format: "%02d:%02d", Int(timeRemaining)/60, Int(timeRemaining)%60))
            .font(.title3.monospacedDigit().bold())
            .foregroundStyle(timeRemaining < 300 ? .red : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(radius: 3)
    }
}
