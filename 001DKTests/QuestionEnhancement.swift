//
//  QuestionEnhancement.swift
//  001DKTests
//
//  Created by Aytac Akyildiz on 30/03/2026.
//

//
//  QuestionDistributionTests.swift
//  borgerDkTests
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

    /// Builds a mock question pool for a given category
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
        let source = QuestionSource(from: nil)
        XCTAssertEqual(source, .unknown)
    }

    func test_examFieldAI_uppercase_isAI() {
        let source = QuestionSource(from: "AI")
        XCTAssertEqual(source, .ai)
    }

    func test_examFieldAI_lowercase_isAI() {
        let source = QuestionSource(from: "ai")
        XCTAssertEqual(source, .ai)
    }

    func test_examFieldAI_mixedCase_isAI() {
        let source = QuestionSource(from: "Ai")
        XCTAssertEqual(source, .ai)
    }

    func test_examFieldYear_isReal() {
        let source = QuestionSource(from: "2024")
        XCTAssertEqual(source, .real)
    }

    func test_examFieldExamName_isReal() {
        let source = QuestionSource(from: "Indfødsretsprøven2023")
        XCTAssertEqual(source, .real)
    }

    func test_examFieldEmptyString_isReal() {
        // Empty string is not nil and not "AI" so treated as real
        let source = QuestionSource(from: "")
        XCTAssertEqual(source, .real)
    }

    // MARK: - CategoryConfig tests

    func test_categoryConfig_totalIsSum() {
        let config = CategoryConfig(realCount: 8, aiCount: 4)
        XCTAssertEqual(config.total, 12)
    }

    func test_categoryConfig_zeroAI_totalEqualsReal() {
        let config = CategoryConfig(realCount: 12, aiCount: 0)
        XCTAssertEqual(config.total, 12)
    }

    func test_categoryConfig_zeroReal_totalEqualsAI() {
        let config = CategoryConfig(realCount: 0, aiCount: 12)
        XCTAssertEqual(config.total, 12)
    }

    // MARK: - TestConfiguration validation tests

    func test_defaultConfig_isValid() {
        // Current config: history 12 + culture 10 + society 13 = 35
        XCTAssertTrue(TestConfiguration.isValid)
    }

    func test_defaultConfig_totalIs45() {
        XCTAssertEqual(TestConfiguration.totalQuestions, 45)
    }

    func test_defaultConfig_mainTotalIs35() {
        XCTAssertEqual(TestConfiguration.totalMainQuestions, 35)
    }

    func test_defaultConfig_recentEventsIs5() {
        XCTAssertEqual(TestConfiguration.recentEventsCount, 5)
    }

    func test_defaultConfig_valuesIs5() {
        XCTAssertEqual(TestConfiguration.valuesCount, 5)
    }

    // MARK: - Distribution selection logic tests

    /// Simulates what generateMainTestQuestions does for a single category
    func selectForCategory(
        category: String,
        config: CategoryConfig,
        pool: [Question]
    ) -> [Question] {
        let realQuestions    = pool.filter { $0.category == category && $0.source == .real }
        let aiQuestions      = pool.filter { $0.category == category && $0.source == .ai }
        let unknownQuestions = pool.filter { $0.category == category && $0.source == .unknown }

        let realTaken = Array(realQuestions.shuffled().prefix(config.realCount))
        let aiTaken   = Array(aiQuestions.shuffled().prefix(config.aiCount))

        let alreadyTaken = realTaken + aiTaken
        let shortfall = config.total - alreadyTaken.count

        var fallback: [Question] = []
        if shortfall > 0 {
            let pool = (unknownQuestions + realQuestions + aiQuestions)
                .filter { !alreadyTaken.contains($0) }
                .shuffled()
            fallback = Array(pool.prefix(shortfall))
        }

        return realTaken + aiTaken + fallback
    }

    func test_exactRealAndAI_picksCorrectCounts() {
        let pool = makePool(category: "history", realCount: 20, aiCount: 10)
        let config = CategoryConfig(realCount: 8, aiCount: 4)
        let selected = selectForCategory(category: "history", config: config, pool: pool)

        let selectedReal = selected.filter { $0.source == .real }
        let selectedAI   = selected.filter { $0.source == .ai }

        XCTAssertEqual(selected.count, 12)
        XCTAssertEqual(selectedReal.count, 8)
        XCTAssertEqual(selectedAI.count, 4)
    }

    func test_allRealNoAI_picksCorrectly() {
        let pool = makePool(category: "history", realCount: 20, aiCount: 0)
        let config = CategoryConfig(realCount: 12, aiCount: 0)
        let selected = selectForCategory(category: "history", config: config, pool: pool)

        XCTAssertEqual(selected.count, 12)
        XCTAssertTrue(selected.allSatisfy { $0.source == .real })
    }

    func test_notEnoughAI_fallsBackToReal() {
        // Only 2 AI questions available but config asks for 4
        let pool = makePool(category: "culture", realCount: 20, aiCount: 2)
        let config = CategoryConfig(realCount: 8, aiCount: 4)
        let selected = selectForCategory(category: "culture", config: config, pool: pool)

        // Should still return 12 total, filling shortfall from real pool
        XCTAssertEqual(selected.count, 12)
    }

    func test_notEnoughReal_fallsBackToAI() {
        // Only 5 real questions available but config asks for 8
        let pool = makePool(category: "society", realCount: 5, aiCount: 20)
        let config = CategoryConfig(realCount: 8, aiCount: 4)
        let selected = selectForCategory(category: "society", config: config, pool: pool)

        // Should still return 12 total
        XCTAssertEqual(selected.count, 12)
    }

    func test_noduplicates_inSelection() {
        let pool = makePool(category: "history", realCount: 20, aiCount: 10)
        let config = CategoryConfig(realCount: 8, aiCount: 4)
        let selected = selectForCategory(category: "history", config: config, pool: pool)

        let uniqueIDs = Set(selected.map { $0.id })
        XCTAssertEqual(uniqueIDs.count, selected.count)
    }

    func test_selectionNeverExceedsPoolSize() {
        // Pool has only 5 questions total but config asks for 12
        let pool = makePool(category: "history", realCount: 3, aiCount: 2)
        let config = CategoryConfig(realCount: 8, aiCount: 4)
        let selected = selectForCategory(category: "history", config: config, pool: pool)

        // Can't exceed what's available
        XCTAssertLessThanOrEqual(selected.count, 5)
    }

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

    func test_fromRaw_realExam_setsRealSource() {
        let raw = RawQuestion(
            exam: "2024",
            question: "Test?",
            options: ["A": "One", "B": "Two", "C": "Three"],
            correct: "A"
        )
        let question = Question.fromRaw(raw, category: "history", index: 0)
        XCTAssertEqual(question.source, .real)
    }

    func test_fromRaw_aiExam_setsAISource() {
        let raw = RawQuestion(
            exam: "AI",
            question: "Test?",
            options: ["A": "One", "B": "Two", "C": "Three"],
            correct: "A"
        )
        let question = Question.fromRaw(raw, category: "history", index: 0)
        XCTAssertEqual(question.source, .ai)
    }

    func test_fromRaw_nilExam_setsUnknownSource() {
        let raw = RawQuestion(
            exam: nil,
            question: "Test?",
            options: ["A": "One", "B": "Two", "C": "Three"],
            correct: "A"
        )
        let question = Question.fromRaw(raw, category: "history", index: 0)
        XCTAssertEqual(question.source, .unknown)
    }
}
