//
//  QuestionManager.swift
//  001DK
//
//  Created by Aytac Akyildiz on 29/03/2026.
//

import Foundation
import Combine

// MARK: - Raw JSON Model (matches your realCulture.json exactly)
struct RawQuestion: Codable {
    let exam: String?
    let question: String
    let options: [String: String]
    let correct: String
}

// MARK: - Clean Question Model
struct Question: Identifiable, Equatable, Codable {
    let id: String
    let text: String
    let choices: [String]
    let correctIndex: Int
    let explanation: String?
    let category: String
    
    var correctAnswer: String { choices[correctIndex] }
}

// MARK: - QuestionManager
@MainActor
class QuestionManager: ObservableObject {
    
    @Published var allQuestions: [Question] = []
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var usingCachedData = false
    
    private let cacheKey = "cachedQuestions"
    
    // TODO: Replace these with your actual 5 raw GitHub URLs
    private let fileURLs: [String: String] = [
         "culture": "https://raw.githubusercontent.com/aytacioachilles/citizenDK/main/realCulture.json",
        "recent": "https://raw.githubusercontent.com/aytacioachilles/citizenDK/main/realEvents.json",   // replace
        "history": "https://raw.githubusercontent.com/aytacioachilles/citizenDK/main/realHistory.json", // replace
        "society":  "https://raw.githubusercontent.com/aytacioachilles/citizenDK/main/realPublic.json",  // replace
        "values":  "https://raw.githubusercontent.com/aytacioachilles/citizenDK/main/realValues.json"     ]
    
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
        }
        else if let cached = loadFromCache() {
            allQuestions = cached
            usingCachedData = true
            print("⚠️ Using cached questions (\(cached.count) questions)")
        }
        else {
            lastError = "Could not load any questions."
            print("❌ FAILED: No fresh data and no cache available")
        }
        
        isLoading = false
        print("🏁 Load process finished. Total questions: \(allQuestions.count)")
    }
    
    private func downloadAllFiles() async -> [Question]? {
        var combined: [Question] = []
        
        for (category, urlString) in fileURLs {
            guard let url = URL(string: urlString) else { continue }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let rawQuestions = try JSONDecoder().decode([RawQuestion].self, from: data)
                
                let converted = rawQuestions.enumerated().map { index, raw in
                    Question.fromRaw(raw, category: category, index: index)
                }
                
                combined.append(contentsOf: converted)
                print("Loaded \(converted.count) questions from \(category)")
            } catch {
                print("Failed to load \(category): \(error.localizedDescription)")
                return nil
            }
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
    
    // MARK: - HELPER METHODS
    func questionsForCategory(_ category: String) -> [Question] {
        allQuestions.filter { $0.category == category }
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
    
    /// Returns exactly 'count' mixed main questions (shuffled)
    func getMixedMainQuestions(count: Int) -> [Question] {
        Array(mainStudyQuestions.shuffled().prefix(count))
    }
    
    // MARK: - Test Generation (Configurable)
    
    /// Generates the first 35 mixed questions according to TestConfiguration
    func generateMainTestQuestions() -> [Question] {
        var selected: [Question] = []
        
        for (category, count) in TestConfiguration.mainCategoryDistribution {
            let categoryQuestions = questionsForCategory(category)
            let shuffled = categoryQuestions.shuffled()
            let taken = Array(shuffled.prefix(count))
            selected.append(contentsOf: taken)
        }
        
        // Shuffle all selected main questions to avoid obvious grouping
        return selected.shuffled()
    }
    
    /// Creates a complete realistic 45-question practice test
    func createPracticeTest() -> [Question] {
        guard TestConfiguration.isValid else {
            print("⚠️ Warning: Main category distribution does not sum to 35")
            // Fallback to old method
            return getMixedMainQuestions(count: 35)
        }
        
        var testQuestions: [Question] = []
        
        // 1. Main categories (configurable distribution)
        testQuestions.append(contentsOf: generateMainTestQuestions())
        
        // 2. Recent Events (positions 36-40)
        let recent = Array(recentQuestions.shuffled().prefix(TestConfiguration.recentEventsCount))
        testQuestions.append(contentsOf: recent)
        
        // 3. Danish Values (positions 41-45)
        let values = Array(valuesQuestions.shuffled().prefix(TestConfiguration.valuesCount))
        testQuestions.append(contentsOf: values)
        
        return testQuestions
    }}

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
            category: category
        )
    }
}
