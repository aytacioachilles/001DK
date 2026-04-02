//
//  SplashScreenView.swift
//  001DK
//

import SwiftUI

struct SplashScreenView: View {
    @State private var flagOffsetY: CGFloat = -320
    @State private var flagOpacity: Double  = 0
    @State private var textOffsetY: CGFloat = 60
    @State private var textOpacity: Double  = 0
    @State private var showMain = false

    var body: some View {
        if showMain {
            ContentView()
                .transition(.opacity)
        } else {
            ZStack {
                Color(red: 0.78, green: 0.08, blue: 0.12)
                    .ignoresSafeArea()

                VStack(spacing: 36) {

                    // ── Dannebrog flag ───────────────────────────────
                    DannebrogView()
                        .frame(width: 200, height: 133)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
                        .offset(y: flagOffsetY)
                        .opacity(flagOpacity)

                    // ── Tagline ──────────────────────────────────────
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
    }

    private func runAnimation() {
        // Flag drops in
        withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.1)) {
            flagOffsetY = 0
            flagOpacity = 1
        }

        // Text slides up shortly after
        withAnimation(.easeOut(duration: 0.55).delay(0.45)) {
            textOffsetY = 0
            textOpacity = 1
        }

        // Transition to main app
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showMain = true
            }
        }
    }
}

// MARK: - Dannebrog (Danish flag) drawn in SwiftUI
struct DannebrogView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let crossV: CGFloat = w * 0.38   // vertical bar left edge (off-centre, authentic)
            let crossVW: CGFloat = w * 0.13  // vertical bar width
            let crossH: CGFloat = h * 0.13   // horizontal bar half-height

            ZStack {
                // Red background
                Color(red: 0.78, green: 0.08, blue: 0.12)

                // Horizontal white bar
                Rectangle()
                    .fill(.white)
                    .frame(width: w, height: crossH * 2)
                    .position(x: w / 2, y: h / 2)

                // Vertical white bar
                Rectangle()
                    .fill(.white)
                    .frame(width: crossVW, height: h)
                    .position(x: crossV + crossVW / 2, y: h / 2)
            }
        }
    }
}
