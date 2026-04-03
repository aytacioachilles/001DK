//
//  DifficultyRatioTests.swift
//  001DKTests
//

import XCTest
@testable import _01DK

final class DifficultyRatioTests: XCTestCase {

    // MARK: - Pool builder

    private func makeQuestion(id: String, category: String, source: QuestionSource) -> Question {
        Question(id: id, text: "Q \(id)", choices: ["A", "B", "C"],
                 correctIndex: 0, explanation: nil, category: category, source: source)
    }

    private func makePool(category: String, realCount: Int, aiCount: Int) -> [Question] {
        (0..<realCount).map { makeQuestion(id: "\(category)_r\($0)", category: category, source: .real) }
        + (0..<aiCount).map { makeQuestion(id: "\(category)_ai\($0)", category: category, source: .ai) }
    }

    /// Large pool so we never hit the fallback path — tests ratio logic cleanly
    private func makeLargeCitizenshipPool() -> [Question] {
        makePool(category: "history", realCount: 50, aiCount: 50) +
        makePool(category: "culture", realCount: 50, aiCount: 50) +
        makePool(category: "society", realCount: 50, aiCount: 50) +
        makePool(category: "recent",  realCount: 20, aiCount: 0)  +
        makePool(category: "values",  realCount: 20, aiCount: 0)
    }

    private func makeLargeResidencyPool() -> [Question] {
        makePool(category: "history", realCount: 50, aiCount: 50) +
        makePool(category: "culture", realCount: 50, aiCount: 50) +
        makePool(category: "society", realCount: 50, aiCount: 50) +
        makePool(category: "values",  realCount: 20, aiCount: 0)
    }

    /// Simulates generateMainTestQuestions
    private func generateMain(pool: [Question], difficulty: DifficultyLevel,
                              exam: ExamType) -> [Question] {
        var selected: [Question] = []
        let distribution = TestConfiguration.mainCategoryDistribution(for: difficulty, exam: exam)
        for (category, config) in distribution {
            let real    = pool.filter { $0.category == category && $0.source == .real }
            let ai      = pool.filter { $0.category == category && $0.source == .ai }
            let unknown = pool.filter { $0.category == category && $0.source == .unknown }
            let realTaken = Array(real.shuffled().prefix(config.realCount))
            let aiTaken   = Array(ai.shuffled().prefix(config.aiCount))
            let taken     = realTaken + aiTaken
            let shortfall = config.total - taken.count
            var fallback: [Question] = []
            if shortfall > 0 {
                fallback = Array((unknown + real + ai)
                    .filter { !taken.contains($0) }.shuffled().prefix(shortfall))
            }
            selected += realTaken + aiTaken + fallback
        }
        return selected
    }

    /// Simulates createPracticeTest
    private func createTest(pool: [Question], difficulty: DifficultyLevel,
                            exam: ExamType) -> [Question] {
        var test = generateMain(pool: pool, difficulty: difficulty, exam: exam)
        let recentCount = TestConfiguration.recentEventsCount(for: exam)
        if recentCount > 0 {
            test += Array(pool.filter { $0.category == "recent" }.shuffled().prefix(recentCount))
        }
        test += Array(pool.filter { $0.category == "values" }.shuffled()
            .prefix(TestConfiguration.valuesCount(for: exam)))
        return test
    }

    // MARK: - Citizenship · Easy (100% real, 0% AI)

    func test_citizenship_easy_mainQuestionsAllReal() {
        let pool = makeLargeCitizenshipPool()
        let main = generateMain(pool: pool, difficulty: .easy, exam: .citizenship)
        XCTAssertEqual(main.count, 35)
        XCTAssertEqual(main.filter { $0.source == .ai }.count, 0)
        XCTAssertEqual(main.filter { $0.source == .real }.count, 35)
    }

    // MARK: - Citizenship · Standard (≈70% real, ≈30% AI)
    // Expected: history 8r+4ai, culture 5r+2ai, society 11r+5ai = 24 real + 11 AI

    func test_citizenship_standard_mainQuestions_correctRealCount() {
        let pool = makeLargeCitizenshipPool()
        let main = generateMain(pool: pool, difficulty: .standard, exam: .citizenship)
        XCTAssertEqual(main.count, 35)
        XCTAssertEqual(main.filter { $0.source == .real }.count, 24)
    }

    func test_citizenship_standard_mainQuestions_correctAICount() {
        let pool = makeLargeCitizenshipPool()
        let main = generateMain(pool: pool, difficulty: .standard, exam: .citizenship)
        XCTAssertEqual(main.filter { $0.source == .ai }.count, 11)
    }

    func test_citizenship_standard_perCategory_correctSplit() {
        let pool = makeLargeCitizenshipPool()
        let main = generateMain(pool: pool, difficulty: .standard, exam: .citizenship)
        let histReal = main.filter { $0.category == "history" && $0.source == .real }.count
        let histAI   = main.filter { $0.category == "history" && $0.source == .ai   }.count
        let cultReal = main.filter { $0.category == "culture" && $0.source == .real }.count
        let cultAI   = main.filter { $0.category == "culture" && $0.source == .ai   }.count
        let socReal  = main.filter { $0.category == "society" && $0.source == .real }.count
        let socAI    = main.filter { $0.category == "society" && $0.source == .ai   }.count
        XCTAssertEqual(histReal, 8,  "History real")
        XCTAssertEqual(histAI,   4,  "History AI")
        XCTAssertEqual(cultReal, 5,  "Culture real")
        XCTAssertEqual(cultAI,   2,  "Culture AI")
        XCTAssertEqual(socReal,  11, "Society real")
        XCTAssertEqual(socAI,    5,  "Society AI")
    }

    // MARK: - Citizenship · Hard (≈50% real, ≈50% AI)
    // Expected: history 6r+6ai, culture 4r+3ai, society 8r+8ai = 18 real + 17 AI

    func test_citizenship_hard_mainQuestions_correctRealCount() {
        let pool = makeLargeCitizenshipPool()
        let main = generateMain(pool: pool, difficulty: .hard, exam: .citizenship)
        XCTAssertEqual(main.count, 35)
        XCTAssertEqual(main.filter { $0.source == .real }.count, 18)
    }

    func test_citizenship_hard_mainQuestions_correctAICount() {
        let pool = makeLargeCitizenshipPool()
        let main = generateMain(pool: pool, difficulty: .hard, exam: .citizenship)
        XCTAssertEqual(main.filter { $0.source == .ai }.count, 17)
    }

    func test_citizenship_hard_perCategory_correctSplit() {
        let pool = makeLargeCitizenshipPool()
        let main = generateMain(pool: pool, difficulty: .hard, exam: .citizenship)
        let histReal = main.filter { $0.category == "history" && $0.source == .real }.count
        let histAI   = main.filter { $0.category == "history" && $0.source == .ai   }.count
        let cultReal = main.filter { $0.category == "culture" && $0.source == .real }.count
        let cultAI   = main.filter { $0.category == "culture" && $0.source == .ai   }.count
        let socReal  = main.filter { $0.category == "society" && $0.source == .real }.count
        let socAI    = main.filter { $0.category == "society" && $0.source == .ai   }.count
        XCTAssertEqual(histReal, 6, "History real")
        XCTAssertEqual(histAI,   6, "History AI")
        XCTAssertEqual(cultReal, 4, "Culture real")
        XCTAssertEqual(cultAI,   3, "Culture AI")
        XCTAssertEqual(socReal,  8, "Society real")
        XCTAssertEqual(socAI,    8, "Society AI")
    }

    // MARK: - Citizenship · full test totals across all difficulties

    func test_citizenship_allDifficulties_fullTestIs45() {
        let pool = makeLargeCitizenshipPool()
        for difficulty in DifficultyLevel.allCases {
            let test = createTest(pool: pool, difficulty: difficulty, exam: .citizenship)
            XCTAssertEqual(test.count, 45, "\(difficulty.label) should produce 45 questions")
        }
    }

    func test_citizenship_recentAndValues_unchangedByDifficulty() {
        let pool = makeLargeCitizenshipPool()
        for difficulty in DifficultyLevel.allCases {
            let test = createTest(pool: pool, difficulty: difficulty, exam: .citizenship)
            XCTAssertEqual(test.filter { $0.category == "recent" }.count, 5,
                           "Recent: \(difficulty.label)")
            XCTAssertEqual(test.filter { $0.category == "values" }.count, 5,
                           "Values: \(difficulty.label)")
        }
    }

    // MARK: - Residency · Easy (100% real, 0% AI)

    func test_residency_easy_mainQuestionsAllReal() {
        let pool = makeLargeResidencyPool()
        let main = generateMain(pool: pool, difficulty: .easy, exam: .residency)
        XCTAssertEqual(main.count, 22)
        XCTAssertEqual(main.filter { $0.source == .ai }.count, 0)
        XCTAssertEqual(main.filter { $0.source == .real }.count, 22)
    }

    // MARK: - Residency · Standard (≈70% real, ≈30% AI)
    // Expected: history 4r+1ai, culture 4r+1ai, society 8r+4ai = 16 real + 6 AI

    func test_residency_standard_mainQuestions_correctRealCount() {
        let pool = makeLargeResidencyPool()
        let main = generateMain(pool: pool, difficulty: .standard, exam: .residency)
        XCTAssertEqual(main.count, 22)
        XCTAssertEqual(main.filter { $0.source == .real }.count, 16)
    }

    func test_residency_standard_mainQuestions_correctAICount() {
        let pool = makeLargeResidencyPool()
        let main = generateMain(pool: pool, difficulty: .standard, exam: .residency)
        XCTAssertEqual(main.filter { $0.source == .ai }.count, 6)
    }

    func test_residency_standard_perCategory_correctSplit() {
        let pool = makeLargeResidencyPool()
        let main = generateMain(pool: pool, difficulty: .standard, exam: .residency)
        let histReal = main.filter { $0.category == "history" && $0.source == .real }.count
        let histAI   = main.filter { $0.category == "history" && $0.source == .ai   }.count
        let cultReal = main.filter { $0.category == "culture" && $0.source == .real }.count
        let cultAI   = main.filter { $0.category == "culture" && $0.source == .ai   }.count
        let socReal  = main.filter { $0.category == "society" && $0.source == .real }.count
        let socAI    = main.filter { $0.category == "society" && $0.source == .ai   }.count
        XCTAssertEqual(histReal, 4, "History real")
        XCTAssertEqual(histAI,   1, "History AI")
        XCTAssertEqual(cultReal, 4, "Culture real")
        XCTAssertEqual(cultAI,   1, "Culture AI")
        XCTAssertEqual(socReal,  8, "Society real")
        XCTAssertEqual(socAI,    4, "Society AI")
    }

    // MARK: - Residency · Hard (≈50% real, ≈50% AI)
    // Expected: history 3r+2ai, culture 3r+2ai, society 6r+6ai = 12 real + 10 AI

    func test_residency_hard_mainQuestions_correctRealCount() {
        let pool = makeLargeResidencyPool()
        let main = generateMain(pool: pool, difficulty: .hard, exam: .residency)
        XCTAssertEqual(main.count, 22)
        XCTAssertEqual(main.filter { $0.source == .real }.count, 12)
    }

    func test_residency_hard_mainQuestions_correctAICount() {
        let pool = makeLargeResidencyPool()
        let main = generateMain(pool: pool, difficulty: .hard, exam: .residency)
        XCTAssertEqual(main.filter { $0.source == .ai }.count, 10)
    }

    func test_residency_hard_perCategory_correctSplit() {
        let pool = makeLargeResidencyPool()
        let main = generateMain(pool: pool, difficulty: .hard, exam: .residency)
        let histReal = main.filter { $0.category == "history" && $0.source == .real }.count
        let histAI   = main.filter { $0.category == "history" && $0.source == .ai   }.count
        let cultReal = main.filter { $0.category == "culture" && $0.source == .real }.count
        let cultAI   = main.filter { $0.category == "culture" && $0.source == .ai   }.count
        let socReal  = main.filter { $0.category == "society" && $0.source == .real }.count
        let socAI    = main.filter { $0.category == "society" && $0.source == .ai   }.count
        XCTAssertEqual(histReal, 3, "History real")
        XCTAssertEqual(histAI,   2, "History AI")
        XCTAssertEqual(cultReal, 3, "Culture real")
        XCTAssertEqual(cultAI,   2, "Culture AI")
        XCTAssertEqual(socReal,  6, "Society real")
        XCTAssertEqual(socAI,    6, "Society AI")
    }

    // MARK: - Residency · full test totals across all difficulties

    func test_residency_allDifficulties_fullTestIs25() {
        let pool = makeLargeResidencyPool()
        for difficulty in DifficultyLevel.allCases {
            let test = createTest(pool: pool, difficulty: difficulty, exam: .residency)
            XCTAssertEqual(test.count, 25, "\(difficulty.label) should produce 25 questions")
        }
    }

    func test_residency_noRecentQuestions_inAnyDifficulty() {
        let pool = makeLargeResidencyPool()
        for difficulty in DifficultyLevel.allCases {
            let test = createTest(pool: pool, difficulty: difficulty, exam: .residency)
            XCTAssertEqual(test.filter { $0.category == "recent" }.count, 0,
                           "Residency should never have recent questions — \(difficulty.label)")
        }
    }

    func test_residency_valuesCount_unchangedByDifficulty() {
        let pool = makeLargeResidencyPool()
        for difficulty in DifficultyLevel.allCases {
            let test = createTest(pool: pool, difficulty: difficulty, exam: .residency)
            XCTAssertEqual(test.filter { $0.category == "values" }.count, 3,
                           "Values: \(difficulty.label)")
        }
    }

    // MARK: - Cross-exam · difficulty ratios are consistent

    func test_bothExams_easy_hasZeroAIQuestions() {
        let cPool = makeLargeCitizenshipPool()
        let rPool = makeLargeResidencyPool()
        let cMain = generateMain(pool: cPool, difficulty: .easy, exam: .citizenship)
        let rMain = generateMain(pool: rPool, difficulty: .easy, exam: .residency)
        XCTAssertEqual(cMain.filter { $0.source == .ai }.count, 0, "Citizenship easy: no AI")
        XCTAssertEqual(rMain.filter { $0.source == .ai }.count, 0, "Residency easy: no AI")
    }

    func test_bothExams_hard_hasAIQuestions() {
        let cPool = makeLargeCitizenshipPool()
        let rPool = makeLargeResidencyPool()
        let cMain = generateMain(pool: cPool, difficulty: .hard, exam: .citizenship)
        let rMain = generateMain(pool: rPool, difficulty: .hard, exam: .residency)
        XCTAssertGreaterThan(cMain.filter { $0.source == .ai }.count, 0, "Citizenship hard: has AI")
        XCTAssertGreaterThan(rMain.filter { $0.source == .ai }.count, 0, "Residency hard: has AI")
    }

    func test_bothExams_noDuplicates_inAnyDifficulty() {
        let cPool = makeLargeCitizenshipPool()
        let rPool = makeLargeResidencyPool()
        for difficulty in DifficultyLevel.allCases {
            let cTest = createTest(pool: cPool, difficulty: difficulty, exam: .citizenship)
            let rTest = createTest(pool: rPool, difficulty: difficulty, exam: .residency)
            XCTAssertEqual(Set(cTest.map { $0.id }).count, cTest.count,
                           "Citizenship \(difficulty.label): duplicates found")
            XCTAssertEqual(Set(rTest.map { $0.id }).count, rTest.count,
                           "Residency \(difficulty.label): duplicates found")
        }
    }
}
