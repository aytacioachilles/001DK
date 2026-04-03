//
//  ExamType.swift
//  001DK
//

import SwiftUI

enum ExamType: String, Codable, CaseIterable {
    case citizenship = "citizenship"
    case residency   = "residency"

    var displayName: String {
        switch self {
        case .citizenship: return "Indfødsretsprøven"
        case .residency:   return "Medborgerskabsprøven"
        }
    }

    var shortName: String {
        switch self {
        case .citizenship: return "Citizenship"
        case .residency:   return "Residency"
        }
    }

    var description: String {
        switch self {
        case .citizenship: return "Danish citizenship test"
        case .residency:   return "Permanent residency test"
        }
    }

    var questionCount: Int {
        switch self {
        case .citizenship: return 45
        case .residency:   return 25
        }
    }
    
    var minuteCount: Int {
        switch self {
        case .citizenship: return 45
        case .residency:   return 30
        }
    }
    var icon: String {
        switch self {
        case .citizenship: return "magnifyingglass.circle.fill"
        case .residency:   return "paperplane.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .citizenship: return .red
        case .residency:   return .blue
        }
    }
}
