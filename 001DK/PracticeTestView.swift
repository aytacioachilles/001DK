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
    @EnvironmentObject private var examContext: ExamContext

    @State private var testQuestions: [Question] = []
    @State private var userAnswers: [String: Int?] = [:]
    @State private var currentPage = 0
    @State private var timeRemaining: TimeInterval = 0
    @State private var isLoading = true
    @State private var showFinishConfirmation = false
    @State private var showProgressSheet = false
    @State private var pageAppeared = false

    private var totalTime: TimeInterval { Double(examContext.examType.minuteCount) * 60 }
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

    private var timeProgress: Double {
        timeRemaining / totalTime
    }

    private var isLowTime: Bool {
        timeRemaining < 300
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            if isLoading {
                loadingView
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

    // MARK: - Loading view
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
            Text("Preparing your practice test…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Main test view
    private var mainTestView: some View {
        VStack(spacing: 0) {

            // ── Timer progress bar ───────────────────────────────
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemFill))
                        .frame(height: 3)

                    Rectangle()
                        .fill(isLowTime ? Color.red : Color.blue)
                        .frame(width: geo.size.width * timeProgress, height: 3)
                        .animation(.linear(duration: 1), value: timeRemaining)
                }
            }
            .frame(height: 3)

            // ── Top bar ──────────────────────────────────────────
            HStack(alignment: .center, spacing: 12) {

                // Progress button
                Button {
                    showProgressSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "list.bullet.circle")
                            .font(.system(size: 16))
                        Text("\(answeredCount)/\(testQuestions.count)")
                            .font(.subheadline.monospacedDigit().bold())
                    }
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }

                Spacer()

                // Timer
                TimerView(timeRemaining: timeRemaining)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 8)

            // ── Questions ────────────────────────────────────────
            TabView(selection: $currentPage) {
                ForEach(0..<totalPages, id: \.self) { page in
                    let pageQuestions = getQuestionsForPage(page)

                    ScrollView(.vertical) {
                        VStack(spacing: 14) {
                            ForEach(Array(pageQuestions.enumerated()), id: \.element.id) { offset, question in
                                let globalIndex = page * questionsPerPage + offset + 1
                                QuestionView(
                                    viewModel: QuestionViewModel(
                                        question: question,
                                        showFeedback: false,
                                        answerBinding: userAnswersBinding(for: question),
                                        shuffledChoices: shuffledChoicesCache[question.id],
                                        questionNumber: globalIndex
                                    )
                                )
                                .opacity(pageAppeared ? 1 : 0)
                                .offset(y: pageAppeared ? 0 : 20)
                                .animation(
                                    .easeOut(duration: 0.35).delay(Double(offset) * 0.1),
                                    value: pageAppeared
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 100)
                    }
                    .tag(page)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: currentPage) {
                pageAppeared = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation {
                        pageAppeared = true
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation { pageAppeared = true }
                }
            }

            // ── Bottom navigation bar ────────────────────────────
            VStack(spacing: 0) {
                Divider()

                HStack(spacing: 12) {

                    // Previous
                    Button {
                        if currentPage > 0 { currentPage -= 1 }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.subheadline.bold())
                            Text("Prev")
                                .font(.subheadline.bold())
                        }
                        .foregroundStyle(currentPage == 0 ? Color(.systemGray3) : .blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(currentPage == 0
                                    ? Color(.systemFill)
                                    : Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .disabled(currentPage == 0)

                    // Finish
                    Button {
                        showFinishConfirmation = true
                    } label: {
                        Text("Finish")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red)
                            .cornerRadius(12)
                    }

                    // Next
                    Button {
                        if currentPage < totalPages - 1 { currentPage += 1 }
                    } label: {
                        HStack(spacing: 6) {
                            Text("Next")
                                .font(.subheadline.bold())
                            Image(systemName: "chevron.right")
                                .font(.subheadline.bold())
                        }
                        .foregroundStyle(currentPage >= totalPages - 1
                                         ? Color(.systemGray3) : .blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(currentPage >= totalPages - 1
                                    ? Color(.systemFill)
                                    : Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .disabled(currentPage >= totalPages - 1)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            }
        }
    }

    // MARK: - Progress sheet
    private var progressSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

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
                                                .stroke(isCurrentPage ? Color.orange : Color.clear,
                                                        lineWidth: 2.5)
                                        )
                                    Text("\(index + 1)")
                                        .font(.caption.bold())
                                        .foregroundStyle(isAnswered ? .white : .secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    HStack(spacing: 20) {
                        HStack(spacing: 6) {
                            Circle().fill(Color.blue).frame(width: 12, height: 12)
                            Text("Answered").font(.caption).foregroundStyle(.secondary)
                        }
                        HStack(spacing: 6) {
                            Circle().fill(Color(.systemFill)).frame(width: 12, height: 12)
                            Text("Skipped").font(.caption).foregroundStyle(.secondary)
                        }
                        HStack(spacing: 6) {
                            Circle().stroke(Color.orange, lineWidth: 2).frame(width: 12, height: 12)
                            Text("Current page").font(.caption).foregroundStyle(.secondary)
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

        // Only load if questions aren't already available
        if questionManager.allQuestions.isEmpty {
            await questionManager.loadQuestions()
        }

        let difficulty = navController.selectedDifficulty
        testQuestions = questionManager.createPracticeTest(difficulty: difficulty)

        shuffledChoicesCache = [:]
        for question in testQuestions {
            shuffledChoicesCache[question.id] = question.choices.indices
                .map { (originalIndex: $0, text: question.choices[$0]) }
                .shuffled()
        }

        userAnswers = [:]
        currentPage = 0
        timeRemaining = Double(examContext.examType.minuteCount) * 60
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

    @State private var pulse = false

    private var isLowTime: Bool { timeRemaining < 300 }

    var body: some View {
        Text(String(format: "%02d:%02d",
                    Int(timeRemaining) / 60,
                    Int(timeRemaining) % 60))
            .font(.title3.monospacedDigit().bold())
            .foregroundStyle(isLowTime ? .red : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(
                color: isLowTime ? Color.red.opacity(pulse ? 0.5 : 0.15) : Color.clear,
                radius: pulse ? 10 : 4
            )
            .scaleEffect(isLowTime && pulse ? 1.04 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                       value: pulse)
            .onAppear { pulse = true }
            .onChange(of: isLowTime) { oldValue, newValue in
                if newValue {
                    pulse = true
                }
            }
    }
}
