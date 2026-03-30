//
//  TestConfiguration.swift
//  001DK
//
//  Created by Aytac Akyildiz on 29/03/2026.
//

import Foundation

// MARK: - Per category real/AI split
struct CategoryConfig {
    let realCount: Int
    let aiCount: Int
    var total: Int { realCount + aiCount }
}

struct TestConfiguration {

    // MARK: - Main category distribution
    // When you add AI questions to a category, adjust aiCount accordingly
    // Example when ready: CategoryConfig(realCount: 8, aiCount: 4)
    static let mainCategoryDistribution: [String: CategoryConfig] = [
        "history": CategoryConfig(realCount: 12, aiCount: 0),
        "culture": CategoryConfig(realCount: 10, aiCount: 0),
        "society": CategoryConfig(realCount: 13, aiCount: 0),
    ]

    // Fixed slots
    static let recentEventsCount = 5
    static let valuesCount = 5

    // MARK: - Validation
    static var totalMainQuestions: Int {
        mainCategoryDistribution.values.reduce(0) { $0 + $1.total }
    }

    static var totalQuestions: Int {
        totalMainQuestions + recentEventsCount + valuesCount
    }

    static var isValid: Bool {
        totalMainQuestions == 35
    }
}
