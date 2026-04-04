//
//  ScoreStore.swift
//  001DK
//

import Foundation
import Combine
import SwiftUI

// MARK: - Stored wrong answer
struct WrongAnswer: Codable, Identifiable {
    let id: String
    let questionText: String
    let choices: [String]
    let correctIndex: Int
    let userAnswerIndex: Int?
    let explanation: String?
    let category: String

    var correctAnswer: String { choices[correctIndex] }
}

// MARK: - A single completed test result
struct TestResult: Codable, Identifiable {
    let id: UUID
    let date: Date
    let score: Int
    let totalQuestions: Int
    let valuesScore: Int
    let passedOverall: Bool
    let passedValues: Bool
    let wrongAnswers: [WrongAnswer]
    let difficulty: DifficultyLevel
    let examType: ExamType

    // Pass logic mirrors ResultsView — residency only needs overall
    var passed: Bool {
        switch examType {
        case .citizenship: return passedOverall && passedValues
        case .residency:   return passedOverall
        }
    }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}

// MARK: - ScoreStore
class ScoreStore: ObservableObject {
    @Published var results: [TestResult] = []

    private let cacheKey = "savedTestResults"

    init() { load() }

    func save(result: TestResult) {
        results.insert(result, at: 0)
        if results.count > 10 {
            results = Array(results.prefix(10))
        }
        persist()
    }

    func delete(at offsets: IndexSet) {
        results.remove(atOffsets: offsets)
        persist()
    }

    func deleteAll() {
        results = []
        persist()
    }

    private func persist() {
        if let encoded = try? JSONEncoder().encode(results) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode([TestResult].self, from: data)
        else { return }
        results = Array(decoded.prefix(10))
    }
}
