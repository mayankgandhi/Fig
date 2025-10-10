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
    
    enum ExpandableField: Hashable {
        case calendar
        case `repeat`
        case label
        case notes
        case countdown
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
            VStack(spacing: 0) {
                // Main Content
                VStack(spacing: TickerSpacing.md) {
                    // Time Picker
                    timePickerSection
                        .padding(.top, TickerSpacing.sm)
                    
                    // Compact Pill Buttons with Inline Expansion
                    VStack(alignment: .leading, spacing: TickerSpacing.sm) {
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

                            pillButton(icon: "bell.badge", title: "Snooze", isActive: enableSnooze) {
                                TickerHaptics.selection()
                                enableSnooze.toggle()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Show expanded content below all pills
                        if let field = expandedField {
                            expandedContentForField(field)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                        }
                    }
                    .padding(.horizontal, TickerSpacing.md)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Dismiss expanded content when tapping outside
                        if expandedField != nil {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                expandedField = nil
                            }
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
            }
            .background(.ultraThinMaterial)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await saveTicker()
                        }
                    } label: {
                        HStack(spacing: TickerSpacing.xxs) {
                            if isSaving {
                                ProgressView()
                                    .tint(TickerColors.absoluteWhite)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            Text(isSaving ? "Saving..." : "Save")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundStyle(TickerColors.absoluteWhite)
                        .padding(.horizontal, TickerSpacing.sm)
                        .padding(.vertical, TickerSpacing.xs)
                        .background(
                            Capsule()
                                .fill(isSaving ? TickerColors.primary.opacity(0.7) : TickerColors.primary)
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
                updateSmartDate()
            }
        }
        .navigationTransition(.zoom(sourceID: "addButton", in: namespace))
    }
    
    // MARK: - Time Picker Section
    
    private var timePickerSection: some View {
        HStack(spacing: 0) {
            Picker("Hour", selection: $selectedHour) {
                ForEach(0..<24) { hour in
                    Text(String(format: "%02d", hour))
                        .font(.system(size: 40, weight: .medium, design: .rounded))
                        .tag(hour)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: 100)
            
            Text(":")
                .font(.system(size: 40, weight: .medium, design: .rounded))
                .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
            
            Picker("Minute", selection: $selectedMinute) {
                ForEach(0..<60) { minute in
                    Text(String(format: "%02d", minute))
                        .font(.system(size: 40, weight: .medium, design: .rounded))
                        .tag(minute)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: 100)
        }
        .frame(height: 140)
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
                        .padding(TickerSpacing.sm)
                        .background(TickerColors.surface(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))

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
                                        .font(.system(size: 14))
                                    Text(option.rawValue)
                                        .cabinetSubheadline()
                                }
                                .foregroundStyle(repeatOption == option ? TickerColors.absoluteWhite : TickerColors.textPrimary(for: colorScheme))
                                .padding(.horizontal, TickerSpacing.md)
                                .padding(.vertical, TickerSpacing.sm)
                                .frame(maxWidth: .infinity)
                                .background(repeatOption == option ? TickerColors.primary : TickerColors.surface(for: colorScheme).opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: TickerRadius.small))
                            }
                        }
                    }
                    .padding(TickerSpacing.sm)
                    .background(TickerColors.surface(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))

                case .label:
                    TextField("Enter label", text: $tickerLabel)
                        .cabinetBody()
                        .padding(TickerSpacing.md)
                        .background(TickerColors.surface(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))

                case .notes:
                    TextEditor(text: Binding(
                        get: { tickerNotes ?? "" },
                        set: { tickerNotes = $0.isEmpty ? nil : $0 }
                    ))
                    .cabinetBody()
                    .frame(height: 100)
                    .scrollContentBackground(.hidden)
                    .padding(TickerSpacing.sm)
                    .background(TickerColors.surface(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))

                case .countdown:
                    VStack(spacing: TickerSpacing.sm) {
                        Toggle("Enable Countdown", isOn: $enableCountdown)
                            .cabinetFootnote()
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
                            .frame(height: 100)
                        }
                    }
                    .padding(TickerSpacing.md)
                    .background(TickerColors.surface(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: TickerRadius.medium))
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
        
        return HStack(spacing: TickerSpacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(title)
                .cabinetCaption2()
                .lineLimit(1)
        }
        .foregroundStyle(isActive ? TickerColors.absoluteWhite : TickerColors.textPrimary(for: colorScheme))
        .padding(.horizontal, TickerSpacing.sm)
        .padding(.vertical, TickerSpacing.xs)
        .background(isActive ? TickerColors.primary : TickerColors.surface(for: colorScheme))
        .overlay(
            Capsule()
                .strokeBorder(hasValue ? TickerColors.primary.opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
        .clipShape(Capsule())
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
        
        let ticker = Ticker(
            label: tickerLabel.isEmpty ? "Ticker" : tickerLabel,
            isEnabled: true,
            notes: tickerNotes,
            schedule: schedule,
            countdown: countdown,
            presentation: presentation,
            tickerData: nil
        )
        
        do {
            try await alarmService.scheduleAlarm(from: ticker, context: modelContext)
            TickerHaptics.success()
            dismiss()
        } catch {
            TickerHaptics.error()
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Calendar Grid

struct CalendarGrid: View {
    @Binding var selectedDate: Date
    @Environment(\.colorScheme) private var colorScheme
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let calendar = Calendar.current
    private let weekdaySymbols = [
        (id: "sun", label: "S"),
        (id: "mon", label: "M"),
        (id: "tue", label: "T"),
        (id: "wed", label: "W"),
        (id: "thu", label: "T"),
        (id: "fri", label: "F"),
        (id: "sat", label: "S")
    ]
    
    private var monthDays: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var days: [Date?] = []
        var currentDate = monthFirstWeek.start
        
        while days.count < 42 {
            if calendar.isDate(currentDate, equalTo: selectedDate, toGranularity: .month) {
                days.append(currentDate)
            } else {
                days.append(nil)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    TickerHaptics.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
                }
                
                Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                    .cabinetBody()
                    .foregroundStyle(TickerColors.textPrimary(for: colorScheme))
                    .frame(maxWidth: .infinity)
                
                Button {
                    TickerHaptics.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(TickerColors.textSecondary(for: colorScheme))
                }
            }
            
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekdaySymbols, id: \.id) { symbol in
                    Text(symbol.label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(TickerColors.textTertiary(for: colorScheme))
                        .frame(maxWidth: .infinity)
                }
            }
            
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(monthDays.indices, id: \.self) { index in
                    if let date = monthDays[index] {
                        CalendarDayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date)
                        ) {
                            TickerHaptics.selection()
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .frame(height: 32)
                    }
                }
            }
        }
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button(action: onTap) {
            Text(dayNumber)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? TickerColors.absoluteWhite : TickerColors.textPrimary(for: colorScheme))
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(
                    Circle()
                        .fill(isSelected ? TickerColors.primary : .clear)
                )
                .overlay(
                    Circle()
                        .strokeBorder(isToday && !isSelected ? TickerColors.primary : .clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero
        
        init(in containerWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            var maxX: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > containerWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
                maxX = max(maxX, currentX - spacing)
            }
            
            self.size = CGSize(width: maxX, height: currentY + lineHeight)
        }
    }
}

#Preview {
    @Previewable @Namespace var namespace
    AddTickerView(namespace: namespace)
        .modelContainer(for: [Ticker.self])
}
