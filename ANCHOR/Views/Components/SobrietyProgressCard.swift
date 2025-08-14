//
//  SobrietyProgressCard.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI

struct SobrietyProgressCard: View {
    let daysSober: Int
    let progressToNextMilestone: Double
    let nextMilestone: String
    let daysToNextMilestone: Int
    
    var body: some View {
        ANCHORCard(padding: ANCHORDesign.Spacing.lg) {
            VStack(spacing: ANCHORDesign.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: ANCHORDesign.Spacing.xs) {
                        Text("Sobriety Journey")
                            .anchorTextStyle(.title2)
                        
                        Text("Keep going strong!")
                            .anchorTextStyle(.callout)
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: ANCHORDesign.Spacing.lg) {
                    // Days Counter
                    VStack(spacing: ANCHORDesign.Spacing.xs) {
                        Text("\(daysSober)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(ANCHORDesign.Colors.primary)
                        
                        Text("Days Strong")
                            .anchorTextStyle(.caption1)
                    }
                    
                    Spacer()
                    
                    // Progress Ring
                    ZStack {
                        ANCHORProgressRing(
                            progress: progressToNextMilestone,
                            lineWidth: 10,
                            size: 100
                        )
                        
                        VStack(spacing: 2) {
                            Text("\(Int(progressToNextMilestone * 100))%")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(ANCHORDesign.Colors.primary)
                            
                            Text("to \(nextMilestone)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(ANCHORDesign.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                
                // Milestone Progress Bar
                VStack(alignment: .leading, spacing: ANCHORDesign.Spacing.xs) {
                    HStack {
                        Text("Next Milestone")
                            .anchorTextStyle(.footnote)
                        
                        Spacer()
                        
                        Text("\(daysToNextMilestone) days to go")
                            .anchorTextStyle(.footnote)
                    }
                    
                    ProgressView(value: progressToNextMilestone)
                        .progressViewStyle(LinearProgressViewStyle(tint: ANCHORDesign.Colors.accent))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
            }
        }
    }
}

#Preview {
    SobrietyProgressCard(
        daysSober: 45,
        progressToNextMilestone: 0.75,
        nextMilestone: "60 Days",
        daysToNextMilestone: 15
    )
    .padding()
}
