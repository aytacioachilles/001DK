//
//  PracticeTestView.swift
//  001DK
//
//  Created by Aytac Akyildiz on 29/03/2026.


import SwiftUI
import Combine

struct PracticeTestView: View {
    @EnvironmentObject private var questionManager: QuestionManager
    
    @State private var testQuestions: [Question] = []
    @State private var userAnswers: [String: Int?] = [:]
    @State private var currentPage = 0
    @State private var timeRemaining: TimeInterval = 45 * 60
    @State private var showResults = false
    @State private var isLoading = true
    
    private let questionsPerPage = 2
    private let timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Preparing your practice test...")
            } else if showResults {
                ResultsView(questions: testQuestions, userAnswers: userAnswers)
            } else {
                mainTestView
            }
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        .task { await startNewTest() }
        .onReceive(timerPublisher) { _ in
            guard !showResults else { return }
            if timeRemaining > 0 { timeRemaining -= 1 } else { finishTest() }
        }
    }
    
    private var mainTestView: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack(alignment: .center) {
                Text("Question \(currentPage * questionsPerPage + 1) – \(min((currentPage + 1) * questionsPerPage, testQuestions.count)) of \(testQuestions.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                TimerView(timeRemaining: timeRemaining)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 8)
            
            // Questions
            TabView(selection: $currentPage) {
                ForEach(0..<(testQuestions.count / questionsPerPage + 1), id: \.self) { page in
                    let pageQuestions = getQuestionsForPage(page)
                    
                    ScrollView {
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
            .tabViewStyle(.page(indexDisplayMode: .always))
            
            // Bottom navigation
            HStack(spacing: 20) {
                Button("Previous") {
                    if currentPage > 0 { currentPage -= 1 }
                }
                .disabled(currentPage == 0)
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Finish Test", role: .destructive) {
                    finishTest()
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                Button("Next") {
                    if currentPage < (testQuestions.count / questionsPerPage) {
                        currentPage += 1
                    }
                }
                .disabled(currentPage >= testQuestions.count / questionsPerPage)
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemBackground))
        }
    }
    
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
        showResults = true
    }
}

// TimerView
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
