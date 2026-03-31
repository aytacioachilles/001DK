//
//  NavigationController.swift
//  001DK
//
//  Created by Aytac Akyildiz on 30/03/2026.
//

import SwiftUI
import Combine

enum AppRoute: Hashable {
    case practiceTestStart
    case practiceTest
    case results
}

class NavigationController: ObservableObject {
    @Published var path = NavigationPath()
    @Published var testQuestions: [Question] = []
    @Published var userAnswers: [String: Int?] = [:]
    @Published var selectedDifficulty: DifficultyLevel = .standard

    func popToRoot() {
        path = NavigationPath()
        testQuestions = []
        userAnswers = [:]
        selectedDifficulty = .standard
    }
}
