//
//  DifficultyLevel.swift
//  001DKTests
//
//  Created by Aytac Akyildiz on 31/03/2026.
//

//
//  DifficultyDistributionTests.swift
//  borgerDkTests
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

    /// Builds a realistic mixed pool for a category
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

    /// Builds a full allQuestions pool matching the real app structure
    func makeFullPool(
        historyReal: Int, historyAI: Int,
        cultureReal: Int, cultureAI: Int,
        societyReal: Int, societyAI: Int,
        recentReal: Int,
        valuesReal: Int
    ) -> [Question] {
        var pool: [Question] = []
        pool += makePool(category: "history", realCount: historyReal, aiCount: historyAI)
        pool += makePool(category: "culture", realCount: cultureReal, aiCount: cultureAI)
        pool += makePool(category: "society", realCount: societyReal, aiCount: societyAI)
        pool += makePool(category: "recent",  realCount: recentReal,  aiCount: 0)
        pool += makePool(category: "values",  realCount: valuesReal,  aiCount: 0)
        return pool
    }

    /// Simulates generateMainTestQuestions for a given pool and difficulty
    func generateMain(pool: [Question], difficulty: DifficultyLevel) -> [Question] {
        var selected: [Question] = []
        let distribution = TestConfiguration.mainCategoryDistribution(for: difficulty)

        for (category, config) in distribution {
            let realQ    = pool.filter { $0.category == category && $0.source == .real }
            let aiQ      = pool.filter { $0.category == category && $0.source == .ai }
            let unknownQ = pool.filter { $0.category == category && $0.source == .unknown }

            let realTaken = Array(realQ.shuffled().prefix(config.realCount))
            let aiTaken   = Array(aiQ.shuffled().prefix(config.aiCount))

            let alreadyTaken = realTaken + aiTaken
            let shortfall    = config.total - alreadyTaken.count

            var fallback: [Question] = []
            if shortfall > 0 {
                let fallbackPool = (unknownQ + realQ + aiQ)
                    .filter { !alreadyTaken.contains($0) }
                    .shuffled()
                fallback = Array(fallbackPool.prefix(shortfall))
            }

            selected += realTaken + aiTaken + fallback
        }
        return selected
    }

    /// Simulates createPracticeTest for a given pool and difficulty
    func createTest(pool: [Question], difficulty: DifficultyLevel) -> [Question] {
        var test = generateMain(pool: pool, difficulty: difficulty)
        let recent = Array(pool.filter { $0.category == "recent" }.shuffled().prefix(TestConfiguration.recentEventsCount))
        let values = Array(pool.filter { $0.category == "values" }.shuffled().prefix(TestConfiguration.valuesCount))
        test += recent + values
        return test
    }

    // MARK: - DifficultyLevel ratio tests

    func test_easy_ratios_areAllReal() {
        XCTAssertEqual(DifficultyLevel.easy.realRatio, 1.0, accuracy: 0.001)
        XCTAssertEqual(DifficultyLevel.easy.aiRatio, 0.0, accuracy: 0.001)
    }

    func test_standard_ratios_are70_30() {
        XCTAssertEqual(DifficultyLevel.standard.realRatio, 0.7, accuracy: 0.001)
        XCTAssertEqual(DifficultyLevel.standard.aiRatio, 0.3, accuracy: 0.001)
    }

    func test_hard_ratios_are50_50() {
        XCTAssertEqual(DifficultyLevel.hard.realRatio, 0.5, accuracy: 0.001)
        XCTAssertEqual(DifficultyLevel.hard.aiRatio, 0.5, accuracy: 0.001)
    }

    // MARK: - CategoryConfig generation tests

    func test_easy_categoryConfig_history_allReal() {
        let config = DifficultyLevel.easy.categoryConfig(totalCount: 12)
        XCTAssertEqual(config.realCount, 12)
        XCTAssertEqual(config.aiCount, 0)
        XCTAssertEqual(config.total, 12)
    }

    func test_standard_categoryConfig_history() {
        // 12 * 0.7 = 8.4 → rounds to 8 real, 4 AI
        let config = DifficultyLevel.standard.categoryConfig(totalCount: 12)
        XCTAssertEqual(config.realCount, 8)
        XCTAssertEqual(config.aiCount, 4)
        XCTAssertEqual(config.total, 12)
    }

    func test_standard_categoryConfig_culture() {
        // 10 * 0.7 = 7 real, 3 AI
        let config = DifficultyLevel.standard.categoryConfig(totalCount: 10)
        XCTAssertEqual(config.realCount, 7)
        XCTAssertEqual(config.aiCount, 3)
        XCTAssertEqual(config.total, 10)
    }

    func test_standard_categoryConfig_society() {
        // 13 * 0.7 = 9.1 → rounds to 9 real, 4 AI
        let config = DifficultyLevel.standard.categoryConfig(totalCount: 13)
        XCTAssertEqual(config.realCount, 9)
        XCTAssertEqual(config.aiCount, 4)
        XCTAssertEqual(config.total, 13)
    }

    func test_hard_categoryConfig_history() {
        // 12 * 0.5 = 6 real, 6 AI
        let config = DifficultyLevel.hard.categoryConfig(totalCount: 12)
        XCTAssertEqual(config.realCount, 6)
        XCTAssertEqual(config.aiCount, 6)
        XCTAssertEqual(config.total, 12)
    }

    func test_hard_categoryConfig_society() {
        // 13 * 0.5 = 6.5 → rounds to 7 real, 6 AI
        let config = DifficultyLevel.hard.categoryConfig(totalCount: 13)
        XCTAssertEqual(config.realCount, 7)
        XCTAssertEqual(config.aiCount, 6)
        XCTAssertEqual(config.total, 13)
    }

    // MARK: - TestConfiguration tests

    func test_mainCategoryTotals_sumTo35() {
        XCTAssertEqual(TestConfiguration.totalMainQuestions, 35)
    }

    func test_totalQuestions_is45() {
        XCTAssertEqual(TestConfiguration.totalQuestions, 45)
    }

    func test_isValid_isTrue() {
        XCTAssertTrue(TestConfiguration.isValid)
    }

    func test_mainCategoryDistribution_easy_allReal() {
        let dist = TestConfiguration.mainCategoryDistribution(for: .easy)
        for (_, config) in dist {
            XCTAssertEqual(config.aiCount, 0)
            XCTAssertGreaterThan(config.realCount, 0)
        }
    }

    func test_mainCategoryDistribution_hard_hasAI() {
        let dist = TestConfiguration.mainCategoryDistribution(for: .hard)
        for (_, config) in dist {
            XCTAssertGreaterThan(config.aiCount, 0)
        }
    }

    func test_mainCategoryDistribution_totalsUnchangedAcrossDifficulties() {
        // Total per category should be same regardless of difficulty
        let easy     = TestConfiguration.mainCategoryDistribution(for: .easy)
        let standard = TestConfiguration.mainCategoryDistribution(for: .standard)
        let hard     = TestConfiguration.mainCategoryDistribution(for: .hard)

        for category in ["history", "culture", "society"] {
            XCTAssertEqual(easy[category]?.total, standard[category]?.total)
            XCTAssertEqual(standard[category]?.total, hard[category]?.total)
        }
    }

    // MARK: - Full test generation tests

    func test_easy_testContains45Questions_withSufficientPool() {
        let pool = makeFullPool(
            historyReal: 20, historyAI: 0,
            cultureReal: 20, cultureAI: 0,
            societyReal: 20, societyAI: 0,
            recentReal: 10,
            valuesReal: 10
        )
        let test = createTest(pool: pool, difficulty: .easy)
        XCTAssertEqual(test.count, 45)
    }

    func test_standard_testContains45Questions_withSufficientPool() {
        let pool = makeFullPool(
            historyReal: 20, historyAI: 20,
            cultureReal: 20, cultureAI: 20,
            societyReal: 20, societyAI: 20,
            recentReal: 10,
            valuesReal: 10
        )
        let test = createTest(pool: pool, difficulty: .standard)
        XCTAssertEqual(test.count, 45)
    }

    func test_hard_testContains45Questions_withSufficientPool() {
        let pool = makeFullPool(
            historyReal: 20, historyAI: 20,
            cultureReal: 20, cultureAI: 20,
            societyReal: 20, societyAI: 20,
            recentReal: 10,
            valuesReal: 10
        )
        let test = createTest(pool: pool, difficulty: .hard)
        XCTAssertEqual(test.count, 45)
    }

    func test_easy_testHasNoAIQuestions() {
        let pool = makeFullPool(
            historyReal: 20, historyAI: 10,
            cultureReal: 20, cultureAI: 10,
            societyReal: 20, societyAI: 10,
            recentReal: 10,
            valuesReal: 10
        )
        let test = createTest(pool: pool, difficulty: .easy)
        let mainQuestions = test.filter { $0.category != "recent" && $0.category != "values" }
        XCTAssertTrue(mainQuestions.allSatisfy { $0.source != .ai })
    }

    func test_hard_testHasAIQuestions_whenPoolSufficient() {
        let pool = makeFullPool(
            historyReal: 20, historyAI: 20,
            cultureReal: 20, cultureAI: 20,
            societyReal: 20, societyAI: 20,
            recentReal: 10,
            valuesReal: 10
        )
        let test = createTest(pool: pool, difficulty: .hard)
        let mainQuestions = test.filter { $0.category != "recent" && $0.category != "values" }
        XCTAssertTrue(mainQuestions.contains { $0.source == .ai })
    }

    func test_noDuplicates_inGeneratedTest() {
        let pool = makeFullPool(
            historyReal: 20, historyAI: 20,
            cultureReal: 20, cultureAI: 20,
            societyReal: 20, societyAI: 20,
            recentReal: 10,
            valuesReal: 10
        )
        let test = createTest(pool: pool, difficulty: .hard)
        let uniqueIDs = Set(test.map { $0.id })
        XCTAssertEqual(uniqueIDs.count, test.count)
    }

    func test_recentAndValues_alwaysFilledRegardlessOfDifficulty() {
        let pool = makeFullPool(
            historyReal: 20, historyAI: 20,
            cultureReal: 20, cultureAI: 20,
            societyReal: 20, societyAI: 20,
            recentReal: 10,
            valuesReal: 10
        )
        for difficulty in DifficultyLevel.allCases {
            let test = createTest(pool: pool, difficulty: difficulty)
            let recentCount = test.filter { $0.category == "recent" }.count
            let valuesCount = test.filter { $0.category == "values" }.count
            XCTAssertEqual(recentCount, 5, "Recent count wrong for \(difficulty.label)")
            XCTAssertEqual(valuesCount, 5, "Values count wrong for \(difficulty.label)")
        }
    }

    func test_fallback_whenAIPoolInsufficient_stillFills45() {
        // Standard needs some AI but we only provide 2 per category
        let pool = makeFullPool(
            historyReal: 20, historyAI: 2,
            cultureReal: 20, cultureAI: 2,
            societyReal: 20, societyAI: 2,
            recentReal: 10,
            valuesReal: 10
        )
        let test = createTest(pool: pool, difficulty: .standard)
        XCTAssertEqual(test.count, 45)
    }

    func test_fallback_whenRealPoolInsufficient_stillFills45() {
        // Hard needs 50% real but we only provide 3 per category
        let pool = makeFullPool(
            historyReal: 3, historyAI: 20,
            cultureReal: 3, cultureAI: 20,
            societyReal: 3, societyAI: 20,
            recentReal: 10,
            valuesReal: 10
        )
        let test = createTest(pool: pool, difficulty: .hard)
        XCTAssertEqual(test.count, 45)
    }

    func test_standard_mainQuestionsHaveCorrectApproximateRatio() {
        // With a large pool, standard should be roughly 70% real
        let pool = makeFullPool(
            historyReal: 50, historyAI: 50,
            cultureReal: 50, cultureAI: 50,
            societyReal: 50, societyAI: 50,
            recentReal: 10,
            valuesReal: 10
        )
        let test = createTest(pool: pool, difficulty: .standard)
        let mainQuestions = test.filter { $0.category != "recent" && $0.category != "values" }

        // Expected: history 8 real + 4 AI, culture 7 real + 3 AI, society 9 real + 4 AI
        // = 24 real + 11 AI out of 35
        let realCount = mainQuestions.filter { $0.source == .real }.count
        let aiCount   = mainQuestions.filter { $0.source == .ai }.count
        XCTAssertEqual(realCount, 24)
        XCTAssertEqual(aiCount, 11)
    }

    func test_hard_mainQuestionsHaveCorrectApproximateRatio() {
        // With a large pool, hard should be roughly 50% real
        let pool = makeFullPool(
            historyReal: 50, historyAI: 50,
            cultureReal: 50, cultureAI: 50,
            societyReal: 50, societyAI: 50,
            recentReal: 10,
            valuesReal: 10
        )
        let test = createTest(pool: pool, difficulty: .hard)
        let mainQuestions = test.filter { $0.category != "recent" && $0.category != "values" }

        // Expected: history 6+6, culture 5+5, society 7+6 = 18 real + 17 AI
        let realCount = mainQuestions.filter { $0.source == .real }.count
        let aiCount   = mainQuestions.filter { $0.source == .ai }.count
        XCTAssertEqual(realCount, 18)
        XCTAssertEqual(aiCount, 17)
    }

    func test_allDifficulties_mainQuestionsSum35() {
        let pool = makeFullPool(
            historyReal: 50, historyAI: 50,
            cultureReal: 50, cultureAI: 50,
            societyReal: 50, societyAI: 50,
            recentReal: 10,
            valuesReal: 10
        )
        for difficulty in DifficultyLevel.allCases {
            let test = createTest(pool: pool, difficulty: difficulty)
            let mainCount = test.filter {
                $0.category != "recent" && $0.category != "values"
            }.count
            XCTAssertEqual(mainCount, 35, "Main count wrong for \(difficulty.label)")
        }
    }
}
