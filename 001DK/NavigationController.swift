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
    
    func popToRoot() {
        path = NavigationPath()
    }
}
