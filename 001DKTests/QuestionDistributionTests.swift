//
//  QuestionDistributionTests.swift
//  001DKTests
//

import XCTest
@testable import _01DK

final class QuestionDistributionTests: XCTestCase {

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

    // MARK: - QuestionSource detection tests

    func test_examFieldNil_isUnknown() {
        XCTAssertEqual(QuestionSource(from: nil), .unknown)
    }

    func test_examFieldAI_uppercase_isAI() {
        XCTAssertEqual(QuestionSource(from: "AI"), .ai)
    }

    func test_examFieldAI_lowercase_isAI() {
        XCTAssertEqual(QuestionSource(from: "ai"), .ai)
    }

    func test_examFieldAI_mixedCase_isAI() {
        XCTAssertEqual(QuestionSource(from: "Ai"), .ai)
    }

    func test_examFieldYear_isReal() {
        XCTAssertEqual(QuestionSource(from: "2024"), .real)
    }

    func test_examFieldExamName_isReal() {
        XCTAssertEqual(QuestionSource(from: "Indfødsretsprøven2023"), .real)
    }

    func test_examFieldEmptyString_isReal() {
        XCTAssertEqual(QuestionSource(from: ""), .real)
    }

    // MARK: - CategoryConfig tests

    func test_categoryConfig_totalIsSum() {
        XCTAssertEqual(CategoryConfig(realCount: 8, aiCount: 4).total, 12)
    }

    func test_categoryConfig_zeroAI_totalEqualsReal() {
        XCTAssertEqual(CategoryConfig(realCount: 12, aiCount: 0).total, 12)
    }

    func test_categoryConfig_zeroReal_totalEqualsAI() {
        XCTAssertEqual(CategoryConfig(realCount: 0, aiCount: 12).total, 12)
    }

    // MARK: - TestConfiguration validation

    func test_citizenship_isValid() {
        XCTAssertTrue(TestConfiguration.isValid(for: .citizenship))
    }

    func test_citizenship_totalIs45() {
        XCTAssertEqual(TestConfiguration.totalQuestions(for: .citizenship), 45)
    }

    func test_citizenship_mainTotalIs35() {
        XCTAssertEqual(TestConfiguration.totalMainQuestions(for: .citizenship), 35)
    }

    func test_citizenship_recentEventsIs5() {
        XCTAssertEqual(TestConfiguration.recentEventsCount(for: .citizenship), 5)
    }

    func test_citizenship_valuesIs5() {
        XCTAssertEqual(TestConfiguration.valuesCount(for: .citizenship), 5)
    }

    func test_residency_isValid() {
        XCTAssertTrue(TestConfiguration.isValid(for: .residency))
    }

    func test_residency_totalIs25() {
        XCTAssertEqual(TestConfiguration.totalQuestions(for: .residency), 25)
    }

    func test_residency_mainTotalIs22() {
        XCTAssertEqual(TestConfiguration.totalMainQuestions(for: .residency), 22)
    }

    func test_residency_recentEventsIs0() {
        XCTAssertEqual(TestConfiguration.recentEventsCount(for: .residency), 0)
    }

    func test_residency_valuesIs3() {
        XCTAssertEqual(TestConfiguration.valuesCount(for: .residency), 3)
    }

    // MARK: - Distribution selection logic

    func selectForCategory(category: String, config: CategoryConfig, pool: [Question]) -> [Question] {
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
                .filter { !taken.contains($0) }
                .shuffled()
                .prefix(shortfall))
        }
        return realTaken + aiTaken + fallback
    }

    func test_exactRealAndAI_picksCorrectCounts() {
        let pool     = makePool(category: "history", realCount: 20, aiCount: 10)
        let config   = CategoryConfig(realCount: 8, aiCount: 4)
        let selected = selectForCategory(category: "history", config: config, pool: pool)
        XCTAssertEqual(selected.count, 12)
        XCTAssertEqual(selected.filter { $0.source == .real }.count, 8)
        XCTAssertEqual(selected.filter { $0.source == .ai }.count, 4)
    }

    func test_allRealNoAI_picksCorrectly() {
        let pool     = makePool(category: "history", realCount: 20, aiCount: 0)
        let config   = CategoryConfig(realCount: 12, aiCount: 0)
        let selected = selectForCategory(category: "history", config: config, pool: pool)
        XCTAssertEqual(selected.count, 12)
        XCTAssertTrue(selected.allSatisfy { $0.source == .real })
    }

    func test_notEnoughAI_fallsBackToReal() {
        let pool     = makePool(category: "culture", realCount: 20, aiCount: 2)
        let config   = CategoryConfig(realCount: 8, aiCount: 4)
        let selected = selectForCategory(category: "culture", config: config, pool: pool)
        XCTAssertEqual(selected.count, 12)
    }

    func test_notEnoughReal_fallsBackToAI() {
        let pool     = makePool(category: "society", realCount: 5, aiCount: 20)
        let config   = CategoryConfig(realCount: 8, aiCount: 4)
        let selected = selectForCategory(category: "society", config: config, pool: pool)
        XCTAssertEqual(selected.count, 12)
    }

    func test_noDuplicates_inSelection() {
        let pool     = makePool(category: "history", realCount: 20, aiCount: 10)
        let config   = CategoryConfig(realCount: 8, aiCount: 4)
        let selected = selectForCategory(category: "history", config: config, pool: pool)
        XCTAssertEqual(Set(selected.map { $0.id }).count, selected.count)
    }

    func test_selectionNeverExceedsPoolSize() {
        let pool     = makePool(category: "history", realCount: 3, aiCount: 2)
        let config   = CategoryConfig(realCount: 8, aiCount: 4)
        let selected = selectForCategory(category: "history", config: config, pool: pool)
        XCTAssertLessThanOrEqual(selected.count, 5)
    }

    // MARK: - Question source flags

    func test_questionSource_isReal_flag() {
        let q = makeQuestion(id: "1", category: "history", source: .real)
        XCTAssertTrue(q.isReal)
        XCTAssertFalse(q.isAI)
    }

    func test_questionSource_isAI_flag() {
        let q = makeQuestion(id: "1", category: "history", source: .ai)
        XCTAssertTrue(q.isAI)
        XCTAssertFalse(q.isReal)
    }

    // MARK: - fromRaw conversion — now requires examType

    func test_fromRaw_citizenship_realExam_setsRealSource() {
        let raw = RawQuestion(exam: "2024", question: "Test?",
                              options: ["A": "One", "B": "Two", "C": "Three"], correct: "A")
        let q = Question.fromRaw(raw, category: "history", index: 0, examType: .citizenship)
        XCTAssertEqual(q.source, .real)
        XCTAssertTrue(q.id.hasPrefix("citizenship_"))
    }

    func test_fromRaw_citizenship_aiExam_setsAISource() {
        let raw = RawQuestion(exam: "AI", question: "Test?",
                              options: ["A": "One", "B": "Two", "C": "Three"], correct: "A")
        let q = Question.fromRaw(raw, category: "history", index: 0, examType: .citizenship)
        XCTAssertEqual(q.source, .ai)
    }

    func test_fromRaw_residency_setsCorrectIDPrefix() {
        let raw = RawQuestion(exam: "2024", question: "Test?",
                              options: ["A": "One", "B": "Two", "C": "Three"], correct: "B")
        let q = Question.fromRaw(raw, category: "society", index: 3, examType: .residency)
        XCTAssertEqual(q.source, .real)
        XCTAssertTrue(q.id.hasPrefix("residency_"))
        XCTAssertEqual(q.id, "residency_society_3")
    }

    func test_fromRaw_nilExam_setsUnknownSource() {
        let raw = RawQuestion(exam: nil, question: "Test?",
                              options: ["A": "One", "B": "Two", "C": "Three"], correct: "A")
        let q = Question.fromRaw(raw, category: "history", index: 0, examType: .citizenship)
        XCTAssertEqual(q.source, .unknown)
    }

    func test_citizenshipAndResidency_IDsNeverClash() {
        let raw = RawQuestion(exam: "2024", question: "Test?",
                              options: ["A": "One", "B": "Two", "C": "Three"], correct: "A")
        let cq = Question.fromRaw(raw, category: "history", index: 0, examType: .citizenship)
        let rq = Question.fromRaw(raw, category: "history", index: 0, examType: .residency)
        XCTAssertNotEqual(cq.id, rq.id)
    }
}
