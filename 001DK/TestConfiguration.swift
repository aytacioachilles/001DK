//
//  TestConfiguration.swift
//  001DK
//
//  Created by Aytac Akyildiz on 29/03/2026.
//

import Foundation

struct TestConfiguration {
    
    // Configurable distribution for the first 35 questions
    static let mainCategoryDistribution: [String: Int] = [
        "history": 12,   // ← Change these numbers as needed
        "culture": 10,
        "society": 13,
        // Add more categories here if you have them
        // Example: "constitution": 5,
    ]
    
    // Fixed parts
    static let recentEventsCount = 5
    static let valuesCount = 5
    
    // Total should be 45
    static var totalQuestions: Int {
        mainCategoryDistribution.values.reduce(0, +) + recentEventsCount + valuesCount
    }
    
    // Validation
    static var isValid: Bool {
        mainCategoryDistribution.values.reduce(0, +) == 35
    }
}
