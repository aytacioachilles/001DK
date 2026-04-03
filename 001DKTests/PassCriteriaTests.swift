//
//  PassCriteriaTests.swift
//  001DKTests
//

import XCTest
@testable import _01DK

final class PassCriteriaTests: XCTestCase {

    // MARK: - Helper factories

    func makeQuestion(id: String, category: String, correctIndex: Int = 0) -> Question {
        Question(
            id: id,
            text: "Test question \(id)",
            choices: ["Answer A", "Answer B", "Answer C"],
            correctIndex: correctIndex,
            explanation: nil,
            category: category,
            source: .real
        )
    }

    /// Builds a full citizenship test: 35 main + 5 recent + 5 values = 45
    func makeCitizenshipTest() -> [Question] {
        var questions: [Question] = []
        for i in 0..<35 { questions.append(makeQuestion(id: "main_\(i)",   category: "history")) }
        for i in 0..<5  { questions.append(makeQuestion(id: "recent_\(i)", category: "recent")) }
        for i in 0..<5  { questions.append(makeQuestion(id: "values_\(i)", category: "values")) }
        return questions
    }

    /// Builds a full residency test: 22 main + 0 recent + 3 values = 25
    func makeResidencyTest() -> [Question] {
        var questions: [Question] = []
        for i in 0..<22 { questions.append(makeQuestion(id: "main_\(i)",   category: "history")) }
        for i in 0..<3  { questions.append(makeQuestion(id: "values_\(i)", category: "values")) }
        return questions
    }

    func makeAnswers(questions: [Question], correctIDs: Set<String>) -> [String: Int?] {
        var answers: [String: Int?] = [:]
        for q in questions {
            answers[q.id] = correctIDs.contains(q.id)
                ? q.correctIndex
                : (q.correctIndex + 1) % q.choices.count
        }
        return answers
    }

    // MARK: - Score helpers (mirror ResultsView logic)

    func computeScore(questions: [Question], answers: [String: Int?]) -> Int {
        questions.filter { q in
            if let s = answers[q.id], s == q.correctIndex { return true }
            return false
        }.count
    }

    func computeValuesScore(questions: [Question], answers: [String: Int?]) -> Int {
        questions.filter { $0.category == "values" }.filter { q in
            if let s = answers[q.id], s == q.correctIndex { return true }
            return false
        }.count
    }

    func computePassed(questions: [Question], answers: [String: Int?], exam: ExamType) -> Bool {
        let overall = computeScore(questions: questions, answers: answers)
            >= TestConfiguration.passThreshold(for: exam)
        let values  = computeValuesScore(questions: questions, answers: answers)
            >= TestConfiguration.valuesThreshold(for: exam)
        switch exam {
        case .citizenship: return overall && values
        case .residency:   return overall
        }
    }

    // MARK: - Citizenship tests

    func test_citizenship_perfectScore_passes() {
        let questions = makeCitizenshipTest()
        let answers   = makeAnswers(questions: questions, correctIDs: Set(questions.map { $0.id }))
        XCTAssertEqual(computeScore(questions: questions, answers: answers), 45)
        XCTAssertEqual(computeValuesScore(questions: questions, answers: answers), 5)
        XCTAssertTrue(computePassed(questions: questions, answers: answers, exam: .citizenship))
    }

    func test_citizenship_exactly36Overall_and_4Values_passes() {
        let questions = makeCitizenshipTest()
        var ids = Set(questions.prefix(31).map { $0.id })
        ids.formUnion(questions.filter { $0.category == "values" }.prefix(4).map { $0.id })
        ids.formUnion(questions.filter { $0.category == "recent" }.prefix(1).map { $0.id })
        let answers = makeAnswers(questions: questions, correctIDs: ids)
        XCTAssertEqual(computeScore(questions: questions, answers: answers), 36)
        XCTAssertEqual(computeValuesScore(questions: questions, answers: answers), 4)
        XCTAssertTrue(computePassed(questions: questions, answers: answers, exam: .citizenship))
    }

    func test_citizenship_35Overall_fails() {
        let questions = makeCitizenshipTest()
        var ids = Set(questions.prefix(30).map { $0.id })
        ids.formUnion(questions.filter { $0.category == "values" }.prefix(4).map { $0.id })
        ids.formUnion(questions.filter { $0.category == "recent" }.prefix(1).map { $0.id })
        let answers = makeAnswers(questions: questions, correctIDs: ids)
        XCTAssertEqual(computeScore(questions: questions, answers: answers), 35)
        XCTAssertFalse(computePassed(questions: questions, answers: answers, exam: .citizenship))
    }

    func test_citizenship_36Overall_3Values_fails() {
        let questions = makeCitizenshipTest()
        var ids = Set(questions.prefix(33).map { $0.id })
        ids.formUnion(questions.filter { $0.category == "values" }.prefix(3).map { $0.id })
        let answers = makeAnswers(questions: questions, correctIDs: ids)
        XCTAssertGreaterThanOrEqual(computeScore(questions: questions, answers: answers), 36)
        XCTAssertEqual(computeValuesScore(questions: questions, answers: answers), 3)
        XCTAssertFalse(computePassed(questions: questions, answers: answers, exam: .citizenship))
    }

    func test_citizenship_36Overall_0Values_fails() {
        let questions = makeCitizenshipTest()
        let ids = Set(questions.filter { $0.category != "values" }.prefix(36).map { $0.id })
        let answers = makeAnswers(questions: questions, correctIDs: ids)
        XCTAssertEqual(computeValuesScore(questions: questions, answers: answers), 0)
        XCTAssertFalse(computePassed(questions: questions, answers: answers, exam: .citizenship))
    }

    func test_citizenship_allValuesCorrect_butOverallFails() {
        let questions = makeCitizenshipTest()
        let ids     = Set(questions.filter { $0.category == "values" }.map { $0.id })
        let answers = makeAnswers(questions: questions, correctIDs: ids)
        XCTAssertEqual(computeScore(questions: questions, answers: answers), 5)
        XCTAssertFalse(computePassed(questions: questions, answers: answers, exam: .citizenship))
    }

    func test_citizenship_zeroAnswers_fails() {
        let questions = makeCitizenshipTest()
        let answers: [String: Int?] = [:]
        XCTAssertEqual(computeScore(questions: questions, answers: answers), 0)
        XCTAssertFalse(computePassed(questions: questions, answers: answers, exam: .citizenship))
    }

    func test_citizenship_skippedValues_countAsWrong() {
        let questions = makeCitizenshipTest()
        var answers = makeAnswers(
            questions: questions,
            correctIDs: Set(questions.filter { $0.category != "values" }.prefix(36).map { $0.id })
        )
        for q in questions.filter({ $0.category == "values" }) { answers[q.id] = nil }
        XCTAssertEqual(computeValuesScore(questions: questions, answers: answers), 0)
        XCTAssertFalse(computePassed(questions: questions, answers: answers, exam: .citizenship))
    }

    // MARK: - Residency tests

    func test_residency_perfectScore_passes() {
        let questions = makeResidencyTest()
        let answers   = makeAnswers(questions: questions, correctIDs: Set(questions.map { $0.id }))
        XCTAssertEqual(computeScore(questions: questions, answers: answers), 25)
        XCTAssertTrue(computePassed(questions: questions, answers: answers, exam: .residency))
    }

    func test_residency_exactly20Overall_passes() {
        let questions = makeResidencyTest()
        let ids     = Set(questions.prefix(20).map { $0.id })
        let answers = makeAnswers(questions: questions, correctIDs: ids)
        XCTAssertEqual(computeScore(questions: questions, answers: answers), 20)
        XCTAssertTrue(computePassed(questions: questions, answers: answers, exam: .residency))
    }

    func test_residency_19Overall_fails() {
        let questions = makeResidencyTest()
        let ids     = Set(questions.prefix(19).map { $0.id })
        let answers = makeAnswers(questions: questions, correctIDs: ids)
        XCTAssertEqual(computeScore(questions: questions, answers: answers), 19)
        XCTAssertFalse(computePassed(questions: questions, answers: answers, exam: .residency))
    }

    func test_residency_20Overall_0Values_stillPasses() {
        let questions = makeResidencyTest()
        // Get 20 correct from main only, all values wrong
        let ids     = Set(questions.filter { $0.category != "values" }.prefix(20).map { $0.id })
        let answers = makeAnswers(questions: questions, correctIDs: ids)
        XCTAssertEqual(computeScore(questions: questions, answers: answers), 20)
        XCTAssertEqual(computeValuesScore(questions: questions, answers: answers), 0)
        XCTAssertTrue(computePassed(questions: questions, answers: answers, exam: .residency),
                      "Residency has no values sub-threshold — overall alone decides pass")
    }

    func test_residency_zeroAnswers_fails() {
        let questions = makeResidencyTest()
        let answers: [String: Int?] = [:]
        XCTAssertEqual(computeScore(questions: questions, answers: answers), 0)
        XCTAssertFalse(computePassed(questions: questions, answers: answers, exam: .residency))
    }
}
