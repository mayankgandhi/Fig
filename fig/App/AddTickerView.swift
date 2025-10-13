//
//  AddTickerView.swift
//  fig
//
//  Created by Mayank Gandhi on 09/10/25.
//

import SwiftUI
import SwiftData

struct AddTickerView: View {
    let namespace: Namespace.ID
    let prefillTemplate: Ticker?
    let isEditMode: Bool
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AlarmService.self) private var alarmService
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedDate = Date()
    @State private var selectedHour = Calendar.current.component(.hour, from: Date())
    @State private var selectedMinute = Calendar.current.component(.minute, from: Date())
    @State private var tickerLabel = ""
    @State private var tickerNotes: String?
    @State private var repeatOption: RepeatOption = .noRepeat
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    // Expandable fields state
    @State private var expandedField: ExpandableField? = nil
    
    // Countdown options
    @State private var enableCountdown = false
    @State private var countdownHours = 0
    @State private var countdownMinutes = 5
    @State private var countdownSeconds = 0
    
    // Presentation options
    @State private var tintColorHex: String?
    @State private var secondaryButtonType: TickerPresentation.SecondaryButtonType = .none
    @State private var enableSnooze = true
    
    // Icon and color selection
    @State private var selectedIcon: String = "alarm"
    @State private var selectedColorHex: String = "#8B5CF6"
    
    // MARK: - Initialization
    
    init(namespace: Namespace.ID, prefillTemplate: Ticker? = nil, isEditMode: Bool = false) {
        self.namespace = namespace
        self.prefillTemplate = prefillTemplate
        self.isEditMode = isEditMode
    }
    
    enum ExpandableField: Hashable {
        case calendar
        case `repeat`
        case label
        case notes
        case countdown
        case icon
    }
    
    enum RepeatOption: String, CaseIterable {
        case noRepeat = "No repeat"
        case daily = "Daily"
        
        var icon: String {
            switch self {
                case .noRepeat: return "calendar"
                case .daily: return "repeat"
            }
        }
    }
    
    private var displayDate: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDate) {
            return "Today"
        } else if calendar.isDateInTomorrow(selectedDate) {
            return "Tomorrow"
        } else {
            return selectedDate.formatted(.dateTime.month(.abbreviated).day())
        }
    }
    
    private var displayLabel: String {
        tickerLabel.isEmpty ? "Label" : tickerLabel
    }
    
    private var displayNotes: String {
        if let notes = tickerNotes, !notes.isEmpty {
            return String(notes.prefix(15)) + (notes.count > 15 ? "..." : "")
        }
        return "Notes"
    }
    
    private var displayCountdown: String {
        enableCountdown ? "\(countdownHours)h \(countdownMinutes)m" : "Countdown"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TickerSpacing.lg) {
                    // Time Picker Card
                    timePickerSection
                        .padding(.horizontal, TickerSpacing.md)
                        .padding(.vertical, TickerSpacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: TickerRadius.large)
                                .fill(TickerColors.surface(for: colorScheme).opacity(0.6))
                        )
                        .background(
                            RoundedRectangle(cornerRadius: TickerRadius.large)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: TickerRadius.large)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            TickerColors.primary.opacity(0.3),
                                            TickerColors.primary.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
                        .shadow(color: TickerColors.primary.opacity(0.1), radius: 30, x: 0, y: 15)
                        .padding(.horizontal, TickerSpacing.md)
                        .padding(.top, TickerSpacing.md)
                    
                    optionsSection
                    
                    Spacer(minLength: 300)
                }
            }
            .overlay(alignment: .bottom) {
                // Expanded content as overlay
                if let field = expandedField {
                    VStack {
                        Spacer()
                        
                        expandedContentForField(field)
                            .padding(.horizontal, TickerSpacing.md)
                            .padding(.bottom, TickerSpacing.lg)
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                                    removal: .move(edge: .bottom).combined(with: .opacity)
                                )
                            )
                    }
                    .background(
                        ZStack {
                            // Backdrop blur
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .opacity(0.95)
                                .ignoresSafeArea()
                            
                            // Gradient overlay
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.4),
                                    Color.black.opacity(0.2)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .ignoresSafeArea()
                        }
                            .onTapGesture {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    expandedField = nil
                                }
                            }
                    )
                }
            }
            .background(
                ZStack {
                    TickerColors.liquidGlassGradient(for: colorScheme)
                        .ignoresSafeArea()
                    
                    // Subtle overlay for glass effect
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.1)
                        .ignoresSafeArea()
                }
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(isEditMode ? "Edit Alarm" : "New Alarm")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        TickerHaptics.selection()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(TickerColors.textSecondary(for: colorScheme).opacity(0.7))
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            TickerHaptics.selection()
                            await saveTicker()
                        }
                    } label: {
                        HStack(spacing: TickerSpacing.xs) {
                            if isSaving {
                                ProgressView()
                                    .tint(TickerColors.absoluteWhite)
                                    .scaleEffect(0.75)
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            Text(isSaving ? "Saving..." : "Save")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(TickerColors.absoluteWhite)
                        .padding(.horizontal, TickerSpacing.md)
                        .padding(.vertical, TickerSpacing.sm)
                        .background(
                            Capsule()
                                .fill(
                                    isSaving ?
                                    TickerColors.primary.opacity(0.7) :
                                        LinearGradient(
                                            colors: [
                                                TickerColors.primary,
                                                TickerColors.primary.opacity(0.9)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                )
                        )
                        .shadow(
                            color: TickerColors.primary.opacity(isSaving ? 0.2 : 0.4),
                            radius: isSaving ? 4 : 8,
                            x: 0,
                            y: 4
                        )
                    }
                    .disabled(isSaving)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                if let errorMessage {
                    Text(errorMessage)
                }
            }
            .onChange(of: selectedHour) { _, _ in updateSmartDate() }
            .onChange(of: selectedMinute) { _, _ in updateSmartDate() }
            .onAppear {
                if let template = prefillTemplate {
                    prefillFromTemplate(template)
                } else {
                    updateSmartDate()
                }
            }
        }
        .navigationTransition(.zoom(sourceID: "addButton", in: namespace))
    }
    private var optionsSection: some View {
        // Options Section
        VStack(alignment: .leading, spacing: TickerSpacing.sm) {
            Text("OPTIONS")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(TickerColors.textTertiary(for: colorScheme))
                .padding(.horizontal, TickerSpacing.md)
            
            FlowLayout(spacing: TickerSpacing.xs) {
                expandablePillButton(
                    icon: "calendar",
                    title: displayDate,
                    field: .calendar
                )
                
                expandablePillButton(
                    icon: repeatOption.icon,
                    title: repeatOption.rawValue,
                    field: .repeat
                )
                
                expandablePillButton(
                    icon: "tag",
                    title: displayLabel,
                    field: .label
                )
                
                expandablePillButton(
                    icon: "note.text",
                    title: displayNotes,
                    field: .notes
                )
                
                expandablePillButton(
                    icon: "timer",
                    title: displayCountdown,
                    field: .countdown
                )
                
                expandablePillButton(
                    icon: selectedIcon,
                    title: "Icon",
                    field: .icon
                )
                
                pillButton(icon: "bell.badge", title: "Snooze", isActive: enableSnooze) {
                    TickerHaptics.selection()
                    enableSnooze.toggle()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, TickerSpacing.md)
        }
    }
    // MARK: - Time Picker Section
    
    private var timePickerSection: some View {
        VStack(spacing: TickerSpacing.sm) {
            // Title
            Text("Set Time")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
            
            // Time Pickers
            HStack(spacing: 0) {
                Picker("Hour", selection: $selectedHour) {
                    ForEach(0..<24) { hour in
                        Text(String(format: "%02d", hour))
                            .font(.system(size: 44, weight: .semibold, design: .rounded))
                            .tag(hour)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: 100)
                
                Text(":")
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .foregroundStyle(TickerColors.primary)
                    .padding(.horizontal, TickerSpacing.xs)
                
                Picker("Minute", selection: $selectedMinute) {
                    ForEach(0..<60) { minute in
                        Text(String(format: "%02d", minute))
                            .font(.system(size: 44, weight: .semibold, design: .rounded))
                            .tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: 100)
            }
            .frame(height: 150)
        }
    }
    
    // MARK: - Pill Button Component
    
    @ViewBuilder
    private func expandablePillButton(
        icon: String,
        title: String,
        field: ExpandableField
    ) -> some View {
        Button {
            toggleField(field)
        } label: {
            pillButtonContent(icon: icon, title: title, isActive: expandedField == field)
        }
        .allowsHitTesting(true)
    }
    
    @ViewBuilder
    private func expandedContentForField(_ field: ExpandableField) -> some View {
        Group {
            switch field {
                case .calendar:
                    CalendarGrid(selectedDate: $selectedDate)
                        .padding(TickerSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: TickerRadius.large)
                                .fill(TickerColors.surface(for: colorScheme).opacity(0.95))
                        )
                        .background(
                            RoundedRectangle(cornerRadius: TickerRadius.large)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: TickerRadius.large)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: .black.opacity(0.15), radius: 24, x: 0, y: 12)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                case .repeat:
                    HStack(spacing: TickerSpacing.xs) {
                        ForEach(RepeatOption.allCases, id: \.self) { option in
                            Button {
                                TickerHaptics.selection()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    repeatOption = option
                                }
                            } label: {
                                HStack(spacing: TickerSpacing.xxs) {
                                    Image(systemName: option.icon)
                                        .font(.system(size: 14, weight: .medium))
                                    Text(option.rawValue)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                }
                                .foregroundStyle(repeatOption == option ? TickerColors.absoluteWhite : TickerColors.textPrimary(for: colorScheme))
                                .padding(.horizontal, TickerSpacing.md)
                                .padding(.vertical, TickerSpacing.sm)
                                .frame(maxWidth: .infinity)
                                .background(repeatOption == option ? TickerColors.primary : TickerColors.surface(for: colorScheme).opacity(0.5))
                                .background(.ultraThinMaterial.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: TickerRadius.small))
                            }
                        }
                    }
                    .padding(TickerSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: TickerRadius.large)
                            .fill(TickerColors.surface(for: colorScheme).opacity(0.95))
                    )
                    .background(
                        RoundedRectangle(cornerRadius: TickerRadius.large)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: TickerRadius.large)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 24, x: 0, y: 12)
                    
                case .label:
                    TextField("Enter label", text: $tickerLabel)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .padding(TickerSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: TickerRadius.large)
                                .fill(TickerColors.surface(for: colorScheme).opacity(0.95))
                        )
                        .background(
                            RoundedRectangle(cornerRadius: TickerRadius.large)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: TickerRadius.large)
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 24, x: 0, y: 12)
                    
                case .notes:
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: Binding(
                            get: { tickerNotes ?? "" },
                            set: { tickerNotes = $0.isEmpty ? nil : $0 }
                        ))
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .frame(height: 120)
                        .scrollContentBackground(.hidden)
                        .padding(TickerSpacing.sm)
                        
                        // Placeholder text
                        if tickerNotes == nil || tickerNotes!.isEmpty {
                            Text("Add notes...")
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundStyle(TickerColors.textTertiary(for: colorScheme))
                                .padding(TickerSpacing.sm)
                                .padding(.top, 8)
                                .allowsHitTesting(false)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: TickerRadius.large)
                            .fill(TickerColors.surface(for: colorScheme).opacity(0.95))
                    )
                    .background(
                        RoundedRectangle(cornerRadius: TickerRadius.large)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: TickerRadius.large)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 24, x: 0, y: 12)
                    
                case .countdown:
                    VStack(spacing: TickerSpacing.md) {
                        Toggle("Enable Countdown", isOn: $enableCountdown)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .tint(TickerColors.primary)
                        
                        if enableCountdown {
                            HStack(spacing: 0) {
                                Picker("Hours", selection: $countdownHours) {
                                    ForEach(0..<24) { hour in
                                        Text("\(hour)h").tag(hour)
                                    }
                                }
                                .pickerStyle(.wheel)
                                
                                Picker("Minutes", selection: $countdownMinutes) {
                                    ForEach(0..<60) { minute in
                                        Text("\(minute)m").tag(minute)
                                    }
                                }
                                .pickerStyle(.wheel)
                                
                                Picker("Seconds", selection: $countdownSeconds) {
                                    ForEach(0..<60) { second in
                                        Text("\(second)s").tag(second)
                                    }
                                }
                                .pickerStyle(.wheel)
                            }
                            .frame(height: 120)
                        }
                    }
                    .padding(TickerSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: TickerRadius.large)
                            .fill(TickerColors.surface(for: colorScheme).opacity(0.95))
                    )
                    .background(
                        RoundedRectangle(cornerRadius: TickerRadius.large)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: TickerRadius.large)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 24, x: 0, y: 12)
                    
                case .icon:
                    IconPickerView(selectedIcon: $selectedIcon, selectedColorHex: $selectedColorHex)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func pillButton(icon: String, title: String, isActive: Bool, isMenu: Bool = false, action: @escaping () -> Void) -> some View {
        Group {
            if isMenu {
                Menu {
                    ForEach(RepeatOption.allCases, id: \.self) { option in
                        Button {
                            TickerHaptics.selection()
                            repeatOption = option
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                if repeatOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    pillButtonContent(icon: icon, title: title, isActive: isActive)
                }
            } else {
                Button(action: action) {
                    pillButtonContent(icon: icon, title: title, isActive: isActive)
                }
            }
        }
    }
    
    private func pillButtonContent(icon: String, title: String, isActive: Bool) -> some View {
        let hasValue = hasSelectedValue(for: icon, title: title)
        let iconColor = title == "Icon" ? (Color(hex: selectedColorHex) ?? TickerColors.primary) : nil
        
        return HStack(spacing: TickerSpacing.xxs) {
            ZStack {
                // Icon background glow for active state
                if isActive {
                    Circle()
                        .fill(TickerColors.absoluteWhite.opacity(0.2))
                        .frame(width: 20, height: 20)
                        .blur(radius: 4)
                }
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: isActive ? .semibold : .medium))
                    .foregroundStyle(iconColor ?? (isActive ? TickerColors.absoluteWhite : TickerColors.textPrimary(for: colorScheme)))
            }
            
            Text(title)
                .font(.system(size: 13, weight: isActive ? .semibold : .medium, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(isActive ? TickerColors.absoluteWhite : TickerColors.textPrimary(for: colorScheme))
        .padding(.horizontal, TickerSpacing.md)
        .padding(.vertical, TickerSpacing.sm)
        .background(
            ZStack {
                if isActive {
                    // Active gradient background
                    LinearGradient(
                        colors: [
                            TickerColors.primary,
                            TickerColors.primary.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    // Inactive glass background
                    TickerColors.surface(for: colorScheme)
                        .opacity(0.7)
                }
            }
        )
        .background(.ultraThinMaterial.opacity(isActive ? 0.5 : 0.3))
        .overlay(
            Capsule()
                .strokeBorder(
                    hasValue && !isActive ?
                    LinearGradient(
                        colors: [
                            TickerColors.primary.opacity(0.6),
                            TickerColors.primary.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                        LinearGradient(
                            colors: [Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                    lineWidth: 1.5
                )
        )
        .clipShape(Capsule())
        .shadow(
            color: isActive ? TickerColors.primary.opacity(0.4) : Color.black.opacity(0.08),
            radius: isActive ? 8 : 4,
            x: 0,
            y: isActive ? 4 : 2
        )
    }
    
    private func hasSelectedValue(for icon: String, title: String) -> Bool {
        switch icon {
            case "calendar":
                return !Calendar.current.isDateInToday(selectedDate)
            case "tag":
                return !tickerLabel.isEmpty
            case "note.text":
                return tickerNotes != nil && !tickerNotes!.isEmpty
            case "timer":
                return enableCountdown
            case "bell.badge":
                return enableSnooze
            default:
                // For icon selection button, always show it has a value
                if title == "Icon" {
                    return true
                }
                return false
        }
    }
    
    // MARK: - Helper Methods
    
    private func toggleField(_ field: ExpandableField) {
        TickerHaptics.selection()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if expandedField == field {
                expandedField = nil
            } else {
                expandedField = field
            }
        }
    }
    
    // MARK: - Template Prefill Logic
    
    private func prefillFromTemplate(_ template: Ticker) {
        let calendar = Calendar.current
        let now = Date()
        
        // Populate schedule data
        if let schedule = template.schedule {
            switch schedule {
                case .oneTime(let date):
                    selectedHour = calendar.component(.hour, from: date)
                    selectedMinute = calendar.component(.minute, from: date)
                    selectedDate = date >= now ? date : now
                    repeatOption = .noRepeat
                    
                case .daily(let time):
                    selectedHour = time.hour
                    selectedMinute = time.minute
                    repeatOption = .daily
                    
                    // Set selectedDate to next occurrence
                    var components = calendar.dateComponents([.year, .month, .day], from: now)
                    components.hour = time.hour
                    components.minute = time.minute
                    guard let todayOccurrence = calendar.date(from: components) else { return }
                    
                    if todayOccurrence <= now {
                        selectedDate = calendar.date(byAdding: .day, value: 1, to: todayOccurrence) ?? todayOccurrence
                    } else {
                        selectedDate = todayOccurrence
                    }
            }
        }
        
        // Populate label and notes
        tickerLabel = template.label
        tickerNotes = template.notes
        
        // Populate countdown
        if let countdown = template.countdown?.preAlert {
            enableCountdown = true
            countdownHours = countdown.hours
            countdownMinutes = countdown.minutes
            countdownSeconds = countdown.seconds
        } else {
            enableCountdown = false
        }
        
        // Populate icon and color
        if let tickerData = template.tickerData {
            selectedIcon = tickerData.icon ?? "clock"
            selectedColorHex = tickerData.colorHex ?? "#123455"
        }
        
        // Populate presentation options
        tintColorHex = template.presentation.tintColorHex
        secondaryButtonType = template.presentation.secondaryButtonType
        // Note: enableSnooze is not stored in Ticker model, keeping default
    }
    
    // MARK: - Smart Date Logic
    
    private func updateSmartDate() {
        let calendar = Calendar.current
        let now = Date()
        
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = selectedHour
        components.minute = selectedMinute
        
        guard let todayWithSelectedTime = calendar.date(from: components) else { return }
        
        if todayWithSelectedTime < now {
            selectedDate = calendar.date(byAdding: .day, value: 1, to: todayWithSelectedTime) ?? todayWithSelectedTime
        } else {
            selectedDate = todayWithSelectedTime
        }
    }
    
    // MARK: - Save Logic
    
    private func saveTicker() async {
        guard !isSaving else { return }
        
        isSaving = true
        defer { isSaving = false }
        
        let calendar = Calendar.current
        
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        components.hour = selectedHour
        components.minute = selectedMinute
        
        guard let finalDate = calendar.date(from: components) else {
            errorMessage = "Invalid date configuration"
            showingError = true
            return
        }
        
        let schedule: TickerSchedule
        if repeatOption == .daily {
            schedule = .daily(time: TickerSchedule.TimeOfDay(
                hour: selectedHour,
                minute: selectedMinute
            ))
        } else {
            schedule = .oneTime(date: finalDate)
        }
        
        let countdown: TickerCountdown?
        if enableCountdown {
            let duration = TickerCountdown.CountdownDuration(
                hours: countdownHours,
                minutes: countdownMinutes,
                seconds: countdownSeconds
            )
            countdown = TickerCountdown(preAlert: duration, postAlert: nil)
        } else {
            countdown = nil
        }
        
        let presentation = TickerPresentation(
            tintColorHex: tintColorHex,
            secondaryButtonType: secondaryButtonType
        )
        
        // Create TickerData with selected icon and color
        let tickerData = TickerData(
            name: tickerLabel.isEmpty ? "Ticker" : tickerLabel,
            icon: selectedIcon,
            colorHex: selectedColorHex
        )
        
        do {
            if isEditMode, let existingTicker = prefillTemplate {
                // Edit mode: Update the existing ticker
                existingTicker.label = tickerLabel.isEmpty ? "Ticker" : tickerLabel
                existingTicker.notes = tickerNotes
                existingTicker.schedule = schedule
                existingTicker.countdown = countdown
                existingTicker.presentation = presentation
                existingTicker.tickerData = tickerData
                
                try await alarmService.updateAlarm(existingTicker, context: modelContext)
            } else {
                // Create mode: Schedule a new alarm
                let ticker = Ticker(
                    label: tickerLabel.isEmpty ? "Ticker" : tickerLabel,
                    isEnabled: true,
                    notes: tickerNotes,
                    schedule: schedule,
                    countdown: countdown,
                    presentation: presentation,
                    tickerData: tickerData
                )
                
                try await alarmService.scheduleAlarm(from: ticker, context: modelContext)
            }
            
            TickerHaptics.success()
            dismiss()
        } catch {
            TickerHaptics.error()
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}



// MARK: - Flow Layout

#Preview {
    @Previewable @Namespace var namespace
    AddTickerView(namespace: namespace)
        .modelContainer(for: [Ticker.self])
}
