//
//  BreathingExerciseView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI

struct BreathingExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isBreathing = false
    @State private var breathPhase: BreathPhase = .inhale
    @State private var timer: Timer?
    @State private var cycleCount = 0
    @State private var isActive = false
    
    enum BreathPhase: String, CaseIterable {
        case inhale = "Breathe In"
        case hold = "Hold"
        case exhale = "Breathe Out"
        case pause = "Pause"
        
        var duration: Double {
            switch self {
            case .inhale: return 4.0
            case .hold: return 4.0
            case .exhale: return 6.0
            case .pause: return 2.0
            }
        }
        
        var color: Color {
            switch self {
            case .inhale: return .blue
            case .hold: return .purple
            case .exhale: return .green
            case .pause: return .gray
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 40) {
            // Header
            VStack(spacing: 8) {
                Text("Breathing Exercise")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("4-4-6-2 Breathing Pattern")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
            
            // Breathing Circle
            ZStack {
                Circle()
                    .stroke(breathPhase.color.opacity(0.3), lineWidth: 4)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .fill(breathPhase.color.opacity(0.2))
                    .frame(width: isBreathing ? 200 : 100, height: isBreathing ? 200 : 100)
                    .animation(.easeInOut(duration: breathPhase.duration), value: isBreathing)
                
                VStack(spacing: 8) {
                    Text(breathPhase.rawValue)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(breathPhase.color)
                    
                    if isActive {
                        Text("Cycle \(cycleCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Instructions
            if !isActive {
                VStack(spacing: 12) {
                    Text("Find a comfortable position and follow the breathing pattern:")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle().fill(.blue).frame(width: 8, height: 8)
                            Text("Inhale for 4 seconds")
                        }
                        HStack {
                            Circle().fill(.purple).frame(width: 8, height: 8)
                            Text("Hold for 4 seconds")
                        }
                        HStack {
                            Circle().fill(.green).frame(width: 8, height: 8)
                            Text("Exhale for 6 seconds")
                        }
                        HStack {
                            Circle().fill(.gray).frame(width: 8, height: 8)
                            Text("Pause for 2 seconds")
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Control Buttons
            VStack(spacing: 16) {
                Button(action: toggleBreathing) {
                    Text(isActive ? "Stop" : "Start Breathing")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isActive ? .red : .blue)
                        .cornerRadius(12)
                }
                
                if isActive {
                    Button("Reset") {
                        resetExercise()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .onDisappear {
            stopBreathing()
        }
    }
    
    private func toggleBreathing() {
        if isActive {
            stopBreathing()
        } else {
            startBreathing()
        }
    }
    
    private func startBreathing() {
        isActive = true
        cycleCount = 0
        breathPhase = .inhale
        nextBreathPhase()
    }
    
    private func stopBreathing() {
        isActive = false
        isBreathing = false
        timer?.invalidate()
        timer = nil
    }
    
    private func resetExercise() {
        stopBreathing()
        cycleCount = 0
        breathPhase = .inhale
    }
    
    private func nextBreathPhase() {
        guard isActive else { return }
        
        // Animate breathing circle
        withAnimation(.easeInOut(duration: breathPhase.duration)) {
            isBreathing = (breathPhase == .inhale || breathPhase == .hold)
        }
        
        // Schedule next phase
        timer = Timer.scheduledTimer(withTimeInterval: breathPhase.duration, repeats: false) { _ in
            guard isActive else { return }
            
            // Move to next phase
            if let currentIndex = BreathPhase.allCases.firstIndex(of: breathPhase) {
                let nextIndex = (currentIndex + 1) % BreathPhase.allCases.count
                breathPhase = BreathPhase.allCases[nextIndex]
                
                // Increment cycle count after completing exhale
                if breathPhase == .pause {
                    cycleCount += 1
                }
                
                nextBreathPhase()
            }
        }
    }
}

#Preview {
    NavigationView {
        BreathingExerciseView()
            .navigationTitle("Breathing")
            .navigationBarTitleDisplayMode(.inline)
    }
}
