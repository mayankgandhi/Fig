//
//  CreateAlarmTypeView.swift
//  fig
//
//  Form for creating a new alarm type
//

import SwiftUI
import SwiftData

struct CreateAlarmTypeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var selectedIcon = "alarm"
    @State private var selectedColorHex = "#8B5CF6"
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TickerSpacing.xl) {
                    // Header
                    VStack(spacing: TickerSpacing.sm) {
                        Text("Create Alarm Type")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        Text("Choose a name and icon for your custom alarm type")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, TickerSpacing.lg)
                    
                    // Form
                    VStack(spacing: TickerSpacing.lg) {
                        // Name input
                        VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                            Text("Name")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            TextField("Enter alarm type name", text: $name)
                                .textFieldStyle(.roundedBorder)
                                .font(.body)
                        }
                        
                        // Icon picker
                        VStack(alignment: .leading, spacing: TickerSpacing.sm) {
                            Text("Icon & Color")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            IconPickerView(
                                selectedIcon: $selectedIcon,
                                selectedColorHex: $selectedColorHex
                            )
                        }
                    }
                    .padding(.horizontal, TickerSpacing.md)
                    
                    Spacer(minLength: TickerSpacing.xl)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("New Alarm Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAlarmType()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private func saveAlarmType() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let newAlarmType = AlarmType(
            name: trimmedName,
            icon: selectedIcon,
            colorHex: selectedColorHex
        )
        
        TickerHaptics.success()
        modelContext.insert(newAlarmType)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            // Handle error - could show an alert here
            print("Failed to save alarm type: \(error)")
        }
    }
}

#Preview {
    CreateAlarmTypeView()
        .modelContainer(for: AlarmType.self, inMemory: true)
}
