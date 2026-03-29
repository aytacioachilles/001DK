//
//  ContentView.swift
//  001DK
//
//  Created by Aytac Akyildiz on 29/03/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var questionManager = QuestionManager()
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.blue.opacity(0.08), .red.opacity(0.06)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // Header - Fixed wrapping
                    VStack(spacing: 12) {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(.red)
                        
                        Text("Danish Citizenship Prep")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("Indfødsretsprøven")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 30)
                    
                    Spacer()
                    
                    // Main 3 Buttons
                    VStack(spacing: 24) {
                        NavigationLink(destination: PracticeTestStartView()) {
                            MainButton(title: "New Practice Test",
                                       subtitle: "45 questions • 45 minutes",
                                       icon: "clock.fill",
                                       color: .blue)
                        }
                        
                        NavigationLink(destination: TopicListView()) {
                            MainButton(title: "Study by Topic",
                                       subtitle: "Learn calmly without timer",
                                       icon: "book.fill",
                                       color: .green)
                        }
                        
                        NavigationLink(destination: ScoreHistoryView()) {
                            MainButton(title: "My Scores",
                                       subtitle: "Track your progress",
                                       icon: "chart.bar.fill",
                                       color: .orange)
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                    
                    // Status
                    // Replace the current status part with this:
                    if questionManager.isLoading {
                        ProgressView("Downloading latest questions...")
                    } else if let error = questionManager.lastError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    } else if questionManager.usingCachedData {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("No internet — using saved questions")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    } else if questionManager.allQuestions.isEmpty {
                        Text("No questions loaded yet")
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationBarHidden(true)
            }
            .task {
                await questionManager.loadQuestions()
            }
            
        }
        .environmentObject(questionManager)
    }

// Reusable Button
    struct MainButton: View {
        let title: String
        let subtitle: String
        let icon: String
        let color: Color
        
        var body: some View {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(color)
            .cornerRadius(18)
            .shadow(radius: 6, y: 4)
        }
        
    }
}

#Preview {
    ContentView()
}
