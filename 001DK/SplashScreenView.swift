//
//  SplashScreenView.swift
//  001DK
//

import SwiftUI

struct SplashScreenView: View {
    @AppStorage("selectedExamType") private var savedExam: String = ""

    @State private var flagOffsetY: CGFloat = -320
    @State private var flagOpacity: Double  = 0
    @State private var textOffsetY: CGFloat = 60
    @State private var textOpacity: Double  = 0
    @State private var destination: Destination = .none

    enum Destination {
        case none, picker, home(ExamType)
    }

    var body: some View {
        ZStack {
            switch destination {
            case .none:
                splashView
            case .picker:
                ExamPickerView { exam in
                    destination = .home(exam)
                }
                .transition(.opacity)
            case .home(let exam):
                ContentView()
                    .environmentObject(ExamContext(examType: exam))
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: destination)
    }

    // MARK: - Splash
    private var splashView: some View {
        ZStack {
            Color(red: 0.78, green: 0.08, blue: 0.12)
                .ignoresSafeArea()

            VStack(spacing: 36) {
                DannebrogView()
                    .frame(width: 200, height: 133)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
                    .offset(y: flagOffsetY)
                    .opacity(flagOpacity)

                VStack(spacing: 10) {
                    Text("Your path to")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.9))
                    Text("Danish Citizenship")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                }
                .multilineTextAlignment(.center)
                .offset(y: textOffsetY)
                .opacity(textOpacity)
            }
        }
        .onAppear { runAnimation() }
    }

    // MARK: - Animation
    private func runAnimation() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.1)) {
            flagOffsetY = 0
            flagOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.55).delay(0.45)) {
            textOffsetY = 0
            textOpacity = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeInOut(duration: 0.45)) {
                if let exam = ExamType(rawValue: savedExam) {
                    destination = .home(exam)
                } else {
                    destination = .picker
                }
            }
        }
    }
}

// MARK: - Destination Equatable
extension SplashScreenView.Destination: Equatable {
    static func == (lhs: SplashScreenView.Destination,
                    rhs: SplashScreenView.Destination) -> Bool {
        switch (lhs, rhs) {
        case (.none,   .none):             return true
        case (.picker, .picker):           return true
        case (.home(let a), .home(let b)): return a == b
        default:                           return false
        }
    }
}
