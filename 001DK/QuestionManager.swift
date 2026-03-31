//
//  QuestionManager.swift
//  001DK
//
//  Created by Aytac Akyildiz on 29/03/2026.
//

import Foundation
import Combine

// MARK: - Raw JSON Model
struct RawQuestion: Codable {
    let exam: String?
    let question: String
    let options: [String: String]
    let correct: String
}

// MARK: - Question Source
enum QuestionSource: String, Codable {
    case real
    case ai = "AI"
    case unknown

    init(from exam: String?) {
        guard let exam = exam else {
            self = .unknown
            return
        }
        if exam.uppercased() == "AI" {
            self = .ai
        } else {
            self = .real
        }
    }
}

// MARK: - Clean Question Model
struct Question: Identifiable, Equatable, Codable {
    let id: String
    let text: String
    let choices: [String]
    let correctIndex: Int
    let explanation: String?
    let category: String
    let source: QuestionSource

    var correctAnswer: String { choices[correctIndex] }
    var isAI: Bool { source == .ai }
    var isReal: Bool { source == .real }
}

// MARK: - QuestionManager
@MainActor
class QuestionManager: ObservableObject {

    @Published var allQuestions: [Question] = []
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var usingCachedData = false

    private let cacheKey = "cachedQuestions"

    private let fileURLs: [String: String] = [
        "culture": "https://raw.githubusercontent.com/aytacioachilles/citizenDK/main/realCulture.json",
        "recent":  "https://raw.githubusercontent.com/aytacioachilles/citizenDK/main/realEvents.json",
        "history": "https://raw.githubusercontent.com/aytacioachilles/citizenDK/main/realHistory.json",
        "society": "https://raw.githubusercontent.com/aytacioachilles/citizenDK/main/realPublic.json",
        "values":  "https://raw.githubusercontent.com/aytacioachilles/citizenDK/main/realValues.json"
    ]

    init() {}

    func loadQuestions() async {
        isLoading = true
        lastError = nil
        print("🔄 Starting question load...")

        if let freshQuestions = await downloadAllFiles() {
            allQuestions = freshQuestions
            saveToCache(questions: freshQuestions)
            usingCachedData = false
            print("✅ SUCCESS: Loaded \(freshQuestions.count) fresh questions from server")
        } else if let cached = loadFromCache() {
            allQuestions = cached
            usingCachedData = true
            print("⚠️ Using cached questions (\(cached.count) questions)")
        } else {
            lastError = "Could not load any questions."
            print("❌ FAILED: No fresh data and no cache available")
        }

        isLoading = false
        print("🏁 Load process finished. Total questions: \(allQuestions.count)")
    }

    private func downloadAllFiles() async -> [Question]? {
        var combined: [Question] = []
        var anyFailed = false

        for (category, urlString) in fileURLs {
            guard let url = URL(string: urlString) else { continue }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let rawQuestions = try JSONDecoder().decode([RawQuestion].self, from: data)
                let converted = rawQuestions.enumerated().map { index, raw in
                    Question.fromRaw(raw, category: category, index: index)
                }
                combined.append(contentsOf: converted)
                print("✅ Loaded \(converted.count) questions from \(category)")
            } catch {
                print("⚠️ Failed to load \(category): \(error.localizedDescription)")
                anyFailed = true
            }
        }

        if anyFailed {
            print("⚠️ Some files failed — falling back to cache for safety")
            return nil
        }

        return combined.isEmpty ? nil : combined
    }

    private func saveToCache(questions: [Question]) {
        if let encoded = try? JSONEncoder().encode(questions) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
    }

    private func loadFromCache() -> [Question]? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return nil }
        return try? JSONDecoder().decode([Question].self, from: data)
    }

    // MARK: - Helper methods
    func questionsForCategory(_ category: String) -> [Question] {
        allQuestions.filter { $0.category == category }
    }

    func questionsForCategory(_ category: String, source: QuestionSource) -> [Question] {
        allQuestions.filter { $0.category == category && $0.source == source }
    }

    var valuesQuestions: [Question] {
        questionsForCategory("values")
    }

    var recentQuestions: [Question] {
        questionsForCategory("recent")
    }

    var mainStudyQuestions: [Question] {
        allQuestions.filter { $0.category != "values" && $0.category != "recent" }
    }

    func getMixedMainQuestions(count: Int) -> [Question] {
        Array(mainStudyQuestions.shuffled().prefix(count))
    }

    func generateMainTestQuestions(difficulty: DifficultyLevel = .standard) -> [Question] {
        var selected: [Question] = []

        let distribution = TestConfiguration.mainCategoryDistribution(for: difficulty)

        for (category, config) in distribution {
            let realQuestions    = questionsForCategory(category, source: .real)
            let aiQuestions      = questionsForCategory(category, source: .ai)
            let unknownQuestions = questionsForCategory(category, source: .unknown)

            let realTaken = Array(realQuestions.shuffled().prefix(config.realCount))
            let aiTaken   = Array(aiQuestions.shuffled().prefix(config.aiCount))

            let alreadyTaken = realTaken + aiTaken
            let shortfall    = config.total - alreadyTaken.count

            var fallback: [Question] = []
            if shortfall > 0 {
                let pool = (unknownQuestions + realQuestions + aiQuestions)
                    .filter { !alreadyTaken.contains($0) }
                    .shuffled()
                fallback = Array(pool.prefix(shortfall))
                print("⚠️ \(category): short by \(shortfall), filled from fallback pool")
            }

            selected.append(contentsOf: realTaken)
            selected.append(contentsOf: aiTaken)
            selected.append(contentsOf: fallback)
        }

        return selected.shuffled()
    }

    func createPracticeTest(difficulty: DifficultyLevel = .standard) -> [Question] {
        guard TestConfiguration.isValid else {
            print("⚠️ Warning: Main category distribution does not sum to 35")
            return getMixedMainQuestions(count: 35)
        }

        var testQuestions: [Question] = []
        testQuestions.append(contentsOf: generateMainTestQuestions(difficulty: difficulty))

        let recent = Array(recentQuestions.shuffled().prefix(TestConfiguration.recentEventsCount))
        testQuestions.append(contentsOf: recent)

        let values = Array(valuesQuestions.shuffled().prefix(TestConfiguration.valuesCount))
        testQuestions.append(contentsOf: values)

        return testQuestions
    }
}

// MARK: - Conversion Helper
extension Question {
    static func fromRaw(_ raw: RawQuestion, category: String, index: Int) -> Question {
        let optionOrder = ["A", "B", "C"]
        var choices: [String] = []
        var correctIndex = 0

        for (i, key) in optionOrder.enumerated() {
            if let text = raw.options[key] {
                choices.append(text)
                if key == raw.correct {
                    correctIndex = i
                }
            }
        }

        return Question(
            id: "\(category)_\(index)",
            text: raw.question,
            choices: choices,
            correctIndex: correctIndex,
            explanation: nil,
            category: category,
            source: QuestionSource(from: raw.exam)
        )
    }
}
