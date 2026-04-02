//
//  TestConfiguration.swift
//  001DK
//
//  Created by Aytac Akyildiz on 29/03/2026.
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

    // Real/AI split ratio per difficulty (out of 10)
    // e.g. easy = 10/0, standard = 7/3, hard = 5/5
    var realRatio: Double {
        switch self {
        case .easy:     return 1.0
        case .standard: return 0.7
        case .hard:     return 0.5
        }
    }

    var aiRatio: Double { 1.0 - realRatio }

    /// Generates a CategoryConfig for a given total count
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

    // MARK: - Base category totals (difficulty-independent)
    static let mainCategoryTotals: [String: Int] = [
        "history": 12,
        "culture": 7,
        "society": 16,
    ]

    // Fixed slots
    static let recentEventsCount = 5
    static let valuesCount       = 5

    // MARK: - Distribution for a given difficulty
    static func mainCategoryDistribution(for difficulty: DifficultyLevel) -> [String: CategoryConfig] {
        mainCategoryTotals.mapValues { total in
            difficulty.categoryConfig(totalCount: total)
        }
    }

    // MARK: - Validation
    static var totalMainQuestions: Int {
        mainCategoryTotals.values.reduce(0, +)
    }

    static var totalQuestions: Int {
        totalMainQuestions + recentEventsCount + valuesCount
    }

    static var isValid: Bool {
        totalMainQuestions == 35
    }
}
