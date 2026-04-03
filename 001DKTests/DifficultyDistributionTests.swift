//
//  DifficultyDistributionTests.swift
//  001DKTests
//

import XCTest
@testable import _01DK

final class DifficultyDistributionTests: XCTestCase {

    // MARK: - Helper factories

    func makeQuestion(id: String, category: String, source: QuestionSource) -> Question {
        Question(
            id: id,
            text: "Test question \(id)",
            choices: ["Answer A", "Answer B", "Answer C"],
            correctIndex: 0,
            explanation: nil,
            category: category,
            source: source
        )
    }

    func makePool(category: String, realCount: Int, aiCount: Int) -> [Question] {
        var questions: [Question] = []
        for i in 0..<realCount {
            questions.append(makeQuestion(id: "\(category)_real_\(i)", category: category, source: .real))
        }
        for i in 0..<aiCount {
            questions.append(makeQuestion(id: "\(category)_ai_\(i)", category: category, source: .ai))
        }
        return questions
    }

    func makeCitizenshipPool(
        historyReal: Int, historyAI: Int,
        cultureReal: Int, cultureAI: Int,
        societyReal: Int, societyAI: Int,
        recentReal: Int,
        valuesReal: Int
    ) -> [Question] {
        makePool(category: "history", realCount: historyReal, aiCount: historyAI) +
        makePool(category: "culture", realCount: cultureReal, aiCount: cultureAI) +
        makePool(category: "society", realCount: societyReal, aiCount: societyAI) +
        makePool(category: "recent",  realCount: recentReal,  aiCount: 0) +
        makePool(category: "values",  realCount: valuesReal,  aiCount: 0)
    }

    func makeResidencyPool(
        historyReal: Int, historyAI: Int,
        cultureReal: Int, cultureAI: Int,
        societyReal: Int, societyAI: Int,
        valuesReal: Int
    ) -> [Question] {
        makePool(category: "history", realCount: historyReal, aiCount: historyAI) +
        makePool(category: "culture", realCount: cultureReal, aiCount: cultureAI) +
        makePool(category: "society", realCount: societyReal, aiCount: societyAI) +
        makePool(category: "values",  realCount: valuesReal,  aiCount: 0)
    }

    /// Simulates generateMainTestQuestions for a given pool, difficulty and exam
    func generateMain(pool: [Question], difficulty: DifficultyLevel, exam: ExamType) -> [Question] {
        var selected: [Question] = []
        let distribution = TestConfiguration.mainCategoryDistribution(for: difficulty, exam: exam)

        for (category, config) in distribution {
            let realQ    = pool.filter { $0.category == category && $0.source == .real }
            let aiQ      = pool.filter { $0.category == category && $0.source == .ai }
            let unknownQ = pool.filter { $0.category == category && $0.source == .unknown }

            let realTaken = Array(realQ.shuffled().prefix(config.realCount))
            let aiTaken   = Array(aiQ.shuffled().prefix(config.aiCount))
            let taken     = realTaken + aiTaken
            let shortfall = config.total - taken.count

            var fallback: [Question] = []
            if shortfall > 0 {
                let fallbackPool = (unknownQ + realQ + aiQ)
                    .filter { !taken.contains($0) }
                    .shuffled()
                fallback = Array(fallbackPool.prefix(shortfall))
            }
            selected += realTaken + aiTaken + fallback
        }
        return selected
    }

    /// Simulates createPracticeTest for a given pool, difficulty and exam
    func createTest(pool: [Question], difficulty: DifficultyLevel, exam: ExamType) -> [Question] {
        var test = generateMain(pool: pool, difficulty: difficulty, exam: exam)
        let recentCount = TestConfiguration.recentEventsCount(for: exam)
        if recentCount > 0 {
            test += Array(pool.filter { $0.category == "recent" }.shuffled().prefix(recentCount))
        }
        test += Array(pool.filter { $0.category == "values" }.shuffled()
            .prefix(TestConfiguration.valuesCount(for: exam)))
        return test
    }

    // MARK: - DifficultyLevel ratio tests

    func test_easy_ratios_areAllReal() {
        XCTAssertEqual(DifficultyLevel.easy.realRatio, 1.0, accuracy: 0.001)
        XCTAssertEqual(DifficultyLevel.easy.aiRatio,   0.0, accuracy: 0.001)
    }

    func test_standard_ratios_are70_30() {
        XCTAssertEqual(DifficultyLevel.standard.realRatio, 0.7, accuracy: 0.001)
        XCTAssertEqual(DifficultyLevel.standard.aiRatio,   0.3, accuracy: 0.001)
    }

    func test_hard_ratios_are50_50() {
        XCTAssertEqual(DifficultyLevel.hard.realRatio, 0.5, accuracy: 0.001)
        XCTAssertEqual(DifficultyLevel.hard.aiRatio,   0.5, accuracy: 0.001)
    }

    // MARK: - CategoryConfig tests

    func test_easy_categoryConfig_history_allReal() {
        let config = DifficultyLevel.easy.categoryConfig(totalCount: 12)
        XCTAssertEqual(config.realCount, 12)
        XCTAssertEqual(config.aiCount, 0)
        XCTAssertEqual(config.total, 12)
    }

    func test_standard_categoryConfig_history() {
        let config = DifficultyLevel.standard.categoryConfig(totalCount: 12)
        XCTAssertEqual(config.realCount, 8)
        XCTAssertEqual(config.aiCount, 4)
        XCTAssertEqual(config.total, 12)
    }

    func test_hard_categoryConfig_history() {
        let config = DifficultyLevel.hard.categoryConfig(totalCount: 12)
        XCTAssertEqual(config.realCount, 6)
        XCTAssertEqual(config.aiCount, 6)
        XCTAssertEqual(config.total, 12)
    }

    // MARK: - TestConfiguration validation

    func test_citizenship_mainTotals_sumTo35() {
        XCTAssertEqual(TestConfiguration.totalMainQuestions(for: .citizenship), 35)
    }

    func test_citizenship_totalQuestions_is45() {
        XCTAssertEqual(TestConfiguration.totalQuestions(for: .citizenship), 45)
    }

    func test_citizenship_isValid() {
        XCTAssertTrue(TestConfiguration.isValid(for: .citizenship))
    }

    func test_residency_mainTotals_sumTo22() {
        XCTAssertEqual(TestConfiguration.totalMainQuestions(for: .residency), 22)
    }

    func test_residency_totalQuestions_is25() {
        XCTAssertEqual(TestConfiguration.totalQuestions(for: .residency), 25)
    }

    func test_residency_isValid() {
        XCTAssertTrue(TestConfiguration.isValid(for: .residency))
    }

    func test_residency_hasNoRecentEvents() {
        XCTAssertEqual(TestConfiguration.recentEventsCount(for: .residency), 0)
    }

    // MARK: - Citizenship test generation

    func test_citizenship_easy_produces45Questions() {
        let pool = makeCitizenshipPool(
            historyReal: 20, historyAI: 0,
            cultureReal: 20, cultureAI: 0,
            societyReal: 20, societyAI: 0,
            recentReal: 10, valuesReal: 10
        )
        XCTAssertEqual(createTest(pool: pool, difficulty: .easy, exam: .citizenship).count, 45)
    }

    func test_citizenship_standard_produces45Questions() {
        let pool = makeCitizenshipPool(
            historyReal: 20, historyAI: 20,
            cultureReal: 20, cultureAI: 20,
            societyReal: 20, societyAI: 20,
            recentReal: 10, valuesReal: 10
        )
        XCTAssertEqual(createTest(pool: pool, difficulty: .standard, exam: .citizenship).count, 45)
    }

    func test_citizenship_hard_produces45Questions() {
        let pool = makeCitizenshipPool(
            historyReal: 20, historyAI: 20,
            cultureReal: 20, cultureAI: 20,
            societyReal: 20, societyAI: 20,
            recentReal: 10, valuesReal: 10
        )
        XCTAssertEqual(createTest(pool: pool, difficulty: .hard, exam: .citizenship).count, 45)
    }

    func test_citizenship_easy_hasNoAIQuestions() {
        let pool = makeCitizenshipPool(
            historyReal: 20, historyAI: 10,
            cultureReal: 20, cultureAI: 10,
            societyReal: 20, societyAI: 10,
            recentReal: 10, valuesReal: 10
        )
        let test = createTest(pool: pool, difficulty: .easy, exam: .citizenship)
        let main = test.filter { $0.category != "recent" && $0.category != "values" }
        XCTAssertTrue(main.allSatisfy { $0.source != .ai })
    }

    func test_citizenship_noDuplicates() {
        let pool = makeCitizenshipPool(
            historyReal: 20, historyAI: 20,
            cultureReal: 20, cultureAI: 20,
            societyReal: 20, societyAI: 20,
            recentReal: 10, valuesReal: 10
        )
        let test = createTest(pool: pool, difficulty: .hard, exam: .citizenship)
        XCTAssertEqual(Set(test.map { $0.id }).count, test.count)
    }

    func test_citizenship_recentAndValues_alwaysFilled() {
        let pool = makeCitizenshipPool(
            historyReal: 20, historyAI: 20,
            cultureReal: 20, cultureAI: 20,
            societyReal: 20, societyAI: 20,
            recentReal: 10, valuesReal: 10
        )
        for difficulty in DifficultyLevel.allCases {
            let test = createTest(pool: pool, difficulty: difficulty, exam: .citizenship)
            XCTAssertEqual(test.filter { $0.category == "recent" }.count, 5,
                           "Recent wrong for \(difficulty.label)")
            XCTAssertEqual(test.filter { $0.category == "values" }.count, 5,
                           "Values wrong for \(difficulty.label)")
        }
    }

    // MARK: - Residency test generation

    func test_residency_easy_produces25Questions() {
        let pool = makeResidencyPool(
            historyReal: 20, historyAI: 0,
            cultureReal: 20, cultureAI: 0,
            societyReal: 20, societyAI: 0,
            valuesReal: 10
        )
        XCTAssertEqual(createTest(pool: pool, difficulty: .easy, exam: .residency).count, 25)
    }

    func test_residency_standard_produces25Questions() {
        let pool = makeResidencyPool(
            historyReal: 20, historyAI: 20,
            cultureReal: 20, cultureAI: 20,
            societyReal: 20, societyAI: 20,
            valuesReal: 10
        )
        XCTAssertEqual(createTest(pool: pool, difficulty: .standard, exam: .residency).count, 25)
    }

    func test_residency_hard_produces25Questions() {
        let pool = makeResidencyPool(
            historyReal: 20, historyAI: 20,
            cultureReal: 20, cultureAI: 20,
            societyReal: 20, societyAI: 20,
            valuesReal: 10
        )
        XCTAssertEqual(createTest(pool: pool, difficulty: .hard, exam: .residency).count, 25)
    }

    func test_residency_hasNoRecentQuestions_inTest() {
        let pool = makeResidencyPool(
            historyReal: 20, historyAI: 20,
            cultureReal: 20, cultureAI: 20,
            societyReal: 20, societyAI: 20,
            valuesReal: 10
        )
        for difficulty in DifficultyLevel.allCases {
            let test = createTest(pool: pool, difficulty: difficulty, exam: .residency)
            XCTAssertEqual(test.filter { $0.category == "recent" }.count, 0,
                           "Residency should have no recent questions — \(difficulty.label)")
        }
    }

    func test_residency_noDuplicates() {
        let pool = makeResidencyPool(
            historyReal: 20, historyAI: 20,
            cultureReal: 20, cultureAI: 20,
            societyReal: 20, societyAI: 20,
            valuesReal: 10
        )
        let test = createTest(pool: pool, difficulty: .hard, exam: .residency)
        XCTAssertEqual(Set(test.map { $0.id }).count, test.count)
    }

    func test_residency_mainQuestionsSum22() {
        let pool = makeResidencyPool(
            historyReal: 50, historyAI: 50,
            cultureReal: 50, cultureAI: 50,
            societyReal: 50, societyAI: 50,
            valuesReal: 10
        )
        for difficulty in DifficultyLevel.allCases {
            let test = createTest(pool: pool, difficulty: difficulty, exam: .residency)
            let mainCount = test.filter { $0.category != "values" }.count
            XCTAssertEqual(mainCount, 22, "Main count wrong for \(difficulty.label)")
        }
    }
}
