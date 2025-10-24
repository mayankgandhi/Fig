//
//  AlarmTypesSheet.swift
//  fig
//
//  Full-screen sheet for managing alarm types
//

import SwiftUI
import SwiftData

struct AlarmTypesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var alarmTypes: [AlarmType]
    @State private var showCreateAlarmType = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if alarmTypes.isEmpty {
                    emptyStateView
                } else {
                    alarmTypesList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Alarm Types")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        showCreateAlarmType = true
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showCreateAlarmType) {
            CreateAlarmTypeView()
                .presentationDetents([.large])
                .presentationCornerRadius(TickerRadius.large)
                .presentationDragIndicator(.visible)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: TickerSpacing.lg) {
            Spacer()
            
            VStack(spacing: TickerSpacing.md) {
                Image(systemName: "tag.circle")
                    .font(.system(.largeTitle, design: .rounded, weight: .light))
                    .foregroundStyle(.secondary)
                
                VStack(spacing: TickerSpacing.xs) {
                    Text("No alarm types yet")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("Create your first alarm type to get started")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Button("Create Alarm Type") {
                showCreateAlarmType = true
            }
            .tickerPrimaryButton()
            .padding(.horizontal, TickerSpacing.xl)
            
            Spacer()
        }
        .padding(TickerSpacing.xl)
    }
    
    private var alarmTypesList: some View {
        ScrollView {
            LazyVStack(spacing: TickerSpacing.xs) {
                ForEach(alarmTypes) { alarmType in
                    AlarmTypeRow(alarmType: alarmType)
                }
            }
            .padding(.horizontal, TickerSpacing.md)
            .padding(.top, TickerSpacing.md)
        }
    }
}

// MARK: - Alarm Type Row

private struct AlarmTypeRow: View {
    let alarmType: AlarmType
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HStack(spacing: TickerSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(alarmType.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: alarmType.icon)
                    .TickerTitle()
                    .foregroundStyle(alarmType.color)
            }
            
            // Name
            Text(alarmType.displayName)
                .font(.body)
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding(.horizontal, TickerSpacing.md)
        .padding(.vertical, TickerSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: TickerRadius.medium)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: TickerRadius.medium)
                .strokeBorder(Color(.systemGray5), lineWidth: 0.5)
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Delete", role: .destructive) {
                deleteAlarmType()
            }
        }
    }
    
    private func deleteAlarmType() {
        TickerHaptics.standardAction()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            modelContext.delete(alarmType)
        }
    }
}

#Preview {
    AlarmTypesSheet()
        .modelContainer(for: AlarmType.self, inMemory: true)
}
