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
        guard let exam = exam else { self = .unknown; return }
        self = exam.uppercased() == "AI" ? .ai : .real
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
    var isAI: Bool   { source == .ai }
    var isReal: Bool { source == .real }
}

// MARK: - QuestionManager
@MainActor
class QuestionManager: ObservableObject {

    @Published var allQuestions: [Question] = []
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var usingCachedData = false

    private(set) var examType: ExamType

    private var cacheKey: String {
        "cachedQuestions_\(examType.rawValue)"
    }

    // ── URL sets per exam ──────────────────────────────────────────────────
    private let citizenshipURLs: [String: String] = [
        "culture": "https://raw.githubusercontent.com/aytacioachilles/citizenDK/main/realCulture.json",
        "recent":  "https://raw.githubusercontent.com/aytacioachilles/citizenDK/main/realEvents.json",
        "history": "https://raw.githubusercontent.com/aytacioachilles/citizenDK/main/realHistory.json",
        "society": "https://raw.githubusercontent.com/aytacioachilles/citizenDK/main/realPublic.json",
        "values":  "https://raw.githubusercontent.com/aytacioachilles/citizenDK/main/realValues.json",
    ]

    private let residencyURLs: [String: String] = [
        "culture": "https://raw.githubusercontent.com/aytacioachilles/citizenDK/main/realCultureB.json",
        "history": "https://raw.githubusercontent.com/aytacioachilles/citizenDK/main/realHistoryB.json",
        "society": "https://raw.githubusercontent.com/aytacioachilles/citizenDK/main/realSocietyB.json",
        "values":  "https://raw.githubusercontent.com/aytacioachilles/citizenDK/main/realValuesB.json",
    ]

    private var fileURLs: [String: String] {
        switch examType {
        case .citizenship: return citizenshipURLs
        case .residency:   return residencyURLs
        }
    }

    init(examType: ExamType = .citizenship) {
        self.examType = examType
    }

    // ── Switch exam and reload ─────────────────────────────────────────────
    func switchExam(to exam: ExamType) async {
        examType = exam
        allQuestions = []
        await loadQuestions()
    }

    // ── Load ───────────────────────────────────────────────────────────────
    func loadQuestions() async {
        isLoading = true
        lastError = nil

        let fresh = await downloadAllFiles()

        if !fresh.isEmpty {
            allQuestions = fresh
            saveToCache(questions: fresh)
            usingCachedData = false
        } else if let cached = loadFromCache(), !cached.isEmpty {
            allQuestions = cached
            usingCachedData = true
        } else {
            lastError = "Could not load questions. Please check your internet connection."
        }

        isLoading = false
    }

    // ── Download — per-file failures are skipped, not fatal ───────────────
    private func downloadAllFiles() async -> [Question] {
        var combined: [Question] = []

        for (category, urlString) in fileURLs {
            guard let url = URL(string: urlString) else { continue }
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                    continue
                }
                let rawQuestions = try JSONDecoder().decode([RawQuestion].self, from: data)
                let converted = rawQuestions.enumerated().map { index, raw in
                    Question.fromRaw(raw, category: category, index: index, examType: examType)
                }
                combined.append(contentsOf: converted)
            } catch {
                // Skip failed files silently — cached data will cover offline use
            }
        }

        return combined
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

    // MARK: - Helpers
    func questionsForCategory(_ category: String) -> [Question] {
        allQuestions.filter { $0.category == category }
    }

    func questionsForCategory(_ category: String, source: QuestionSource) -> [Question] {
        allQuestions.filter { $0.category == category && $0.source == source }
    }

    var valuesQuestions: [Question]    { questionsForCategory("values") }
    var recentQuestions: [Question]    { questionsForCategory("recent") }
    var mainStudyQuestions: [Question] {
        allQuestions.filter { $0.category != "values" && $0.category != "recent" }
    }

    func getMixedMainQuestions(count: Int) -> [Question] {
        Array(mainStudyQuestions.shuffled().prefix(count))
    }

    // MARK: - Test generation
    func generateMainTestQuestions(difficulty: DifficultyLevel) -> [Question] {
        var selected: [Question] = []
        let distribution = TestConfiguration.mainCategoryDistribution(
            for: difficulty, exam: examType)

        for (category, config) in distribution {
            let real    = questionsForCategory(category, source: .real)
            let ai      = questionsForCategory(category, source: .ai)
            let unknown = questionsForCategory(category, source: .unknown)

            let realTaken = Array(real.shuffled().prefix(config.realCount))
            let aiTaken   = Array(ai.shuffled().prefix(config.aiCount))
            let taken     = realTaken + aiTaken
            let shortfall = config.total - taken.count

            var fallback: [Question] = []
            if shortfall > 0 {
                let pool = (unknown + real + ai)
                    .filter { !taken.contains($0) }
                    .shuffled()
                fallback = Array(pool.prefix(shortfall))
            }

            selected.append(contentsOf: realTaken + aiTaken + fallback)
        }

        return selected.shuffled()
    }

    func createPracticeTest(difficulty: DifficultyLevel = .standard) -> [Question] {
        guard TestConfiguration.isValid(for: examType) else {
            return getMixedMainQuestions(count: TestConfiguration.totalMainQuestions(for: examType))
        }

        var test: [Question] = []
        test.append(contentsOf: generateMainTestQuestions(difficulty: difficulty))

        let recentCount = TestConfiguration.recentEventsCount(for: examType)
        if recentCount > 0 {
            test.append(contentsOf: Array(recentQuestions.shuffled().prefix(recentCount)))
        }

        let valuesCount = TestConfiguration.valuesCount(for: examType)
        test.append(contentsOf: Array(valuesQuestions.shuffled().prefix(valuesCount)))

        return test
    }
}

// MARK: - Conversion Helper
extension Question {
    static func fromRaw(_ raw: RawQuestion, category: String,
                        index: Int, examType: ExamType) -> Question {
        let optionOrder = ["A", "B", "C"]
        var choices: [String] = []
        var correctIndex = 0

        for (i, key) in optionOrder.enumerated() {
            if let text = raw.options[key] {
                choices.append(text)
                if key == raw.correct { correctIndex = i }
            }
        }

        return Question(
            id: "\(examType.rawValue)_\(category)_\(index)",
            text: raw.question,
            choices: choices,
            correctIndex: correctIndex,
            explanation: nil,
            category: category,
            source: QuestionSource(from: raw.exam)
        )
    }
}
