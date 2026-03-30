//
//  PassCriteriaTests.swift
//  001DKTests
//
//  Created by Aytac Akyildiz on 30/03/2026.
//

//
//  ResultsViewTests.swift
//  borgerDkTests
//

import XCTest
@testable import _01DK

final class PassCriteriaTests: XCTestCase {

    // MARK: - Helper factories

    /// Creates a dummy question for a given category
    func makeQuestion(id: String, category: String, correctIndex: Int = 0) -> Question {
        Question(
            id: id,
            text: "Test question \(id)",
            choices: ["Answer A", "Answer B", "Answer C"],
            correctIndex: correctIndex,
            explanation: nil,
            category: category
        )
    }

    /// Builds a full 45-question set matching real test structure:
    /// 35 main + 5 recent + 5 values
    func makeFullTest() -> [Question] {
        var questions: [Question] = []

        // 35 main questions (history/culture/society)
        for i in 0..<35 {
            questions.append(makeQuestion(id: "main_\(i)", category: "history", correctIndex: 0))
        }

        // 5 recent events
        for i in 0..<5 {
            questions.append(makeQuestion(id: "recent_\(i)", category: "recent", correctIndex: 0))
        }

        // 5 values
        for i in 0..<5 {
            questions.append(makeQuestion(id: "values_\(i)", category: "values", correctIndex: 0))
        }

        return questions
    }

    /// Builds a userAnswers dict — pass which question IDs to answer correctly
    func makeAnswers(questions: [Question], correctIDs: Set<String>) -> [String: Int?] {
        var answers: [String: Int?] = [:]
        for q in questions {
            if correctIDs.contains(q.id) {
                answers[q.id] = q.correctIndex       // correct answer
            } else {
                answers[q.id] = (q.correctIndex + 1) % q.choices.count  // wrong answer
            }
        }
        return answers
    }

    // MARK: - Score computation helpers (mirrors ResultsView logic)

    func computeScore(questions: [Question], answers: [String: Int?]) -> Int {
        questions.filter { q in
            if let selected = answers[q.id], selected == q.correctIndex { return true }
            return false
        }.count
    }

    func computeValuesScore(questions: [Question], answers: [String: Int?]) -> Int {
        questions.filter { $0.category == "values" }.filter { q in
            if let selected = answers[q.id], selected == q.correctIndex { return true }
            return false
        }.count
    }

    func computePassed(questions: [Question], answers: [String: Int?]) -> Bool {
        computeScore(questions: questions, answers: answers) >= 36 &&
        computeValuesScore(questions: questions, answers: answers) >= 4
    }

    // MARK: - Tests

    func test_perfectScore_passes() {
        let questions = makeFullTest()
        let answers = makeAnswers(questions: questions, correctIDs: Set(questions.map { $0.id }))

        XCTAssertEqual(computeScore(questions: questions, answers: answers), 45)
        XCTAssertEqual(computeValuesScore(questions: questions, answers: answers), 5)
        XCTAssertTrue(computePassed(questions: questions, answers: answers))
    }

    func test_exactly36Overall_and_4Values_passes() {
        let questions = makeFullTest()

      
        var ids = Set(questions.prefix(31).map { $0.id })  // 31 main/recent
        ids.formUnion(questions.filter { $0.category == "values" }.prefix(4).map { $0.id })  // 4 values
        ids.formUnion(questions.filter { $0.category == "recent" }.prefix(1).map { $0.id })  // 1 recent

        let answers = makeAnswers(questions: questions, correctIDs: ids)

        XCTAssertEqual(computeScore(questions: questions, answers: answers), 36)
        XCTAssertEqual(computeValuesScore(questions: questions, answers: answers), 4)
        XCTAssertTrue(computePassed(questions: questions, answers: answers))
    }

    func test_35Overall_4Values_fails_overall() {
        let questions = makeFullTest()

        var ids = Set(questions.prefix(30).map { $0.id })
        ids.formUnion(questions.filter { $0.category == "values" }.prefix(4).map { $0.id })
        ids.formUnion(questions.filter { $0.category == "recent" }.prefix(1).map { $0.id })

        let answers = makeAnswers(questions: questions, correctIDs: ids)

        XCTAssertEqual(computeScore(questions: questions, answers: answers), 35)
        XCTAssertEqual(computeValuesScore(questions: questions, answers: answers), 4)
        XCTAssertFalse(computePassed(questions: questions, answers: answers))
    }

    func test_36Overall_3Values_fails_values() {
        let questions = makeFullTest()

        var ids = Set(questions.prefix(33).map { $0.id })  // 33 main/recent correct
        ids.formUnion(questions.filter { $0.category == "values" }.prefix(3).map { $0.id })  // only 3 values

        let answers = makeAnswers(questions: questions, correctIDs: ids)

        XCTAssertGreaterThanOrEqual(computeScore(questions: questions, answers: answers), 36)
        XCTAssertEqual(computeValuesScore(questions: questions, answers: answers), 3)
        XCTAssertFalse(computePassed(questions: questions, answers: answers))
    }

    func test_36Overall_0Values_fails_values() {
        let questions = makeFullTest()

        // 36 correct but zero values correct
        let ids = Set(questions.filter { $0.category != "values" }.prefix(36).map { $0.id })
        let answers = makeAnswers(questions: questions, correctIDs: ids)

        XCTAssertGreaterThanOrEqual(computeScore(questions: questions, answers: answers), 36)
        XCTAssertEqual(computeValuesScore(questions: questions, answers: answers), 0)
        XCTAssertFalse(computePassed(questions: questions, answers: answers))
    }

    func test_allValuesCorrect_butOverallFails() {
        let questions = makeFullTest()

        // Only 5 correct — all values, nothing else
        let ids = Set(questions.filter { $0.category == "values" }.map { $0.id })
        let answers = makeAnswers(questions: questions, correctIDs: ids)

        XCTAssertEqual(computeScore(questions: questions, answers: answers), 5)
        XCTAssertEqual(computeValuesScore(questions: questions, answers: answers), 5)
        XCTAssertFalse(computePassed(questions: questions, answers: answers))
    }

    func test_zeroAnswers_fails() {
        let questions = makeFullTest()
        let answers: [String: Int?] = [:]  // nothing answered

        XCTAssertEqual(computeScore(questions: questions, answers: answers), 0)
        XCTAssertEqual(computeValuesScore(questions: questions, answers: answers), 0)
        XCTAssertFalse(computePassed(questions: questions, answers: answers))
    }

    func test_45Overall_5Values_passes() {
        let questions = makeFullTest()
        let ids = Set(questions.map { $0.id })
        let answers = makeAnswers(questions: questions, correctIDs: ids)

        XCTAssertEqual(computeScore(questions: questions, answers: answers), 45)
        XCTAssertEqual(computeValuesScore(questions: questions, answers: answers), 5)
        XCTAssertTrue(computePassed(questions: questions, answers: answers))
    }

    func test_skippedAnswers_countAsWrong() {
        let questions = makeFullTest()

        // Answer 36 correctly but skip all values questions
        var answers = makeAnswers(
            questions: questions,
            correctIDs: Set(questions.filter { $0.category != "values" }.prefix(36).map { $0.id })
        )
        // Explicitly nil out values answers to simulate skipping
        for q in questions.filter({ $0.category == "values" }) {
            answers[q.id] = nil
        }

        XCTAssertEqual(computeValuesScore(questions: questions, answers: answers), 0)
        XCTAssertFalse(computePassed(questions: questions, answers: answers))
    }
}
