//
//  TestConfiguration.swift
//  001DK
//

import Foundation

// MARK: - Difficulty Level
enum DifficultyLevel: String, Codable, CaseIterable {
    case easy     = "Easy"
    case standard = "Standard"
    case hard     = "Hard"

    var label: String { rawValue }

    var description: String {
        switch self {
        case .easy:     return "Previous exam questions only"
        case .standard: return "Mostly previous exam questions, some AI generated ones"
        case .hard:     return "Equal mix of previous exam and AI generated questions"
        }
    }

    var icon: String {
        switch self {
        case .easy:     return "1.circle.fill"
        case .standard: return "2.circle.fill"
        case .hard:     return "3.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .easy:     return "green"
        case .standard: return "blue"
        case .hard:     return "red"
        }
    }

    var realRatio: Double {
        switch self {
        case .easy:     return 1.0
        case .standard: return 0.7
        case .hard:     return 0.5
        }
    }

    var aiRatio: Double { 1.0 - realRatio }

    func categoryConfig(totalCount: Int) -> CategoryConfig {
        let realCount = Int((Double(totalCount) * realRatio).rounded())
        let aiCount   = totalCount - realCount
        return CategoryConfig(realCount: realCount, aiCount: aiCount)
    }
}

// MARK: - Per category real/AI split
struct CategoryConfig {
    let realCount: Int
    let aiCount: Int
    var total: Int { realCount + aiCount }
}

// MARK: - Test Configuration
struct TestConfiguration {


    static let citizenshipMainCategoryTotals: [String: Int] = [
        "history": 12,
        "culture": 7,
        "society": 16,
    ]
    static let citizenshipRecentEventsCount  = 5
    static let citizenshipValuesCount        = 5
    static let citizenshipPassThreshold      = 36
    static let citizenshipValuesThreshold    = 4

   
    static let residencyMainCategoryTotals: [String: Int] = [
        "history": 5,
        "culture": 5,
        "society": 12,
    ]
    static let residencyRecentEventsCount  = 0   // ← was 3, no recent events category
    static let residencyValuesCount        = 3   // ← was 2, matches citizenship
    static let residencyPassThreshold      = 20  // ← adjust once confirmed
    static let residencyValuesThreshold    = 0   // ← adjust once confirmed

    // MARK: - Exam-aware accessors
    static func mainCategoryTotals(for exam: ExamType) -> [String: Int] {
        switch exam {
        case .citizenship: return citizenshipMainCategoryTotals
        case .residency:   return residencyMainCategoryTotals
        }
    }

    static func recentEventsCount(for exam: ExamType) -> Int {
        switch exam {
        case .citizenship: return citizenshipRecentEventsCount
        case .residency:   return residencyRecentEventsCount
        }
    }

    static func valuesCount(for exam: ExamType) -> Int {
        switch exam {
        case .citizenship: return citizenshipValuesCount
        case .residency:   return residencyValuesCount
        }
    }

    static func passThreshold(for exam: ExamType) -> Int {
        switch exam {
        case .citizenship: return citizenshipPassThreshold
        case .residency:   return residencyPassThreshold
        }
    }

    static func valuesThreshold(for exam: ExamType) -> Int {
        switch exam {
        case .citizenship: return citizenshipValuesThreshold
        case .residency:   return residencyValuesThreshold
        }
    }

    static func mainCategoryDistribution(for difficulty: DifficultyLevel,
                                         exam: ExamType) -> [String: CategoryConfig] {
        mainCategoryTotals(for: exam).mapValues { total in
            difficulty.categoryConfig(totalCount: total)
        }
    }

    // MARK: - Validation
    static func totalMainQuestions(for exam: ExamType) -> Int {
        mainCategoryTotals(for: exam).values.reduce(0, +)
    }

    static func totalQuestions(for exam: ExamType) -> Int {
        totalMainQuestions(for: exam)
            + recentEventsCount(for: exam)
            + valuesCount(for: exam)
    }

    static func isValid(for exam: ExamType) -> Bool {
        switch exam {
        case .citizenship: return totalMainQuestions(for: exam) == 35
        case .residency:   return totalMainQuestions(for: exam) == 22
        }
    }
}
