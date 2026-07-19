//
//  StatisticsView.swift
//  ClipB
//
//  Created by ClipB Team on 2026-07-17.
//  Copyright © 2026 ClipB. All rights reserved.
//

import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject var viewModel: StatisticsViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.spacingXXL) {
                // Header
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.title)
                        .foregroundColor(.clipBPrimary)
                    Text("Statistics & Insights")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                // Summary Cards
                HStack(spacing: DesignTokens.spacingL) {
                    StatMetricCard(title: "Today's Copies", value: "\(viewModel.todayCopies)", icon: "doc.on.doc.fill", color: .blue)
                    StatMetricCard(title: "Total Clipboard Items", value: "\(viewModel.totalEntries)", icon: "history", color: .green)
                    StatMetricCard(title: "Storage Usage", value: viewModel.storageUsed, icon: "arrow.down.circle.fill", color: .purple)
                }
                
                // Charts Section
                HStack(alignment: .top, spacing: DesignTokens.spacingXL) {
                    // Weekly Activity
                    VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                        Text("Weekly Activity")
                            .sectionHeader()
                        
                        Chart {
                            ForEach(viewModel.weeklyActivity) { day in
                                BarMark(
                                    x: .value("Day", day.dayLabel),
                                    y: .value("Copies", day.count)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.clipBGradientStart, Color.clipBGradientEnd],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .cornerRadius(DesignTokens.cornerRadiusSmall)
                            }
                        }
                        .frame(height: 200)
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                    }
                    .padding(DesignTokens.spacingL)
                    .glassCard()
                    
                    // Category Distribution
                    VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                        Text("Categories")
                            .sectionHeader()
                        
                        if viewModel.categoryCounts.isEmpty {
                            Text("No category data yet.")
                                .foregroundColor(.clipBTextSecondary)
                                .frame(maxHeight: .infinity)
                        } else {
                            Chart {
                                ForEach(viewModel.categoryCounts, id: \.category) { item in
                                    BarMark(
                                        x: .value("Count", item.count),
                                        y: .value("Category", item.category)
                                    )
                                    .foregroundStyle(Color.clipBPrimary.opacity(0.8))
                                    .cornerRadius(DesignTokens.cornerRadiusSmall)
                                }
                            }
                            .frame(height: 200)
                            .chartXAxis {
                                AxisMarks(position: .bottom)
                            }
                        }
                    }
                    .padding(DesignTokens.spacingL)
                    .glassCard()
                }
            }
            .padding(DesignTokens.spacingXXL)
        }
        .onAppear {
            viewModel.refresh()
        }
    }
}

// MARK: - Stat Metric Card Component

struct StatMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignTokens.spacingM) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .padding(DesignTokens.spacingS)
                .background(color.opacity(0.12))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.clipBTextPrimary)
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(.clipBTextSecondary)
            }
            Spacer()
        }
        .padding(DesignTokens.spacingL)
        .background(Color.clipBSurfaceElevated.opacity(0.4))
        .cornerRadius(DesignTokens.cornerRadiusLarge)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusLarge)
                .stroke(Color.clipBBorder, lineWidth: 1)
        )
    }
}
