//
//  CreateAlarmIntent.swift
//  fig
//
//  Main AppIntent for creating tickers via Siri voice commands
//

import Foundation
import AppIntents
import SwiftData
import SwiftUI
import Factory

/// Main intent for creating tickers through Siri voice commands
struct CreateAlarmIntent: AppIntent {
    
    static var title: LocalizedStringResource = "Create Ticker"
    static var description = IntentDescription("Create a new ticker alarm")
    static var openAppWhenRun: Bool = false
    
    // MARK: - Parameters
    
    @Parameter(title: "Time", description: "When the ticker should trigger")
    var time: Date
    
    @Parameter(title: "Label", description: "Name for the ticker")
    var label: String?
    
    @Parameter(title: "Repeat", description: "How often the ticker should repeat")
    var repeatFrequency: RepeatFrequencyEnum
    
    @Parameter(title: "Icon", description: "SF Symbol icon name")
    var icon: String?
    
    @Parameter(title: "Color", description: "Hex color for the ticker")
    var colorHex: String?
    
    @Parameter(title: "Sound", description: "Sound name for the ticker")
    var soundName: String?
    
    // MARK: - Initializers
    
    init() {
        self.time = Date()
        self.label = nil
        self.repeatFrequency = .oneTime
        self.icon = nil
        self.colorHex = nil
    }
    
    init(time: Date, label: String? = nil, repeatFrequency: RepeatFrequencyEnum = .oneTime, icon: String? = nil, colorHex: String? = nil, soundName: String? = nil) {
        self.time = time
        self.label = label
        self.repeatFrequency = repeatFrequency
        self.icon = icon
        self.colorHex = colorHex
        self.soundName = soundName
    }
    
    // MARK: - Intent Performance
    
    @MainActor
    func perform() async throws -> some IntentResult {
        print("🔔 CreateAlarmIntent.perform() started")
        print("   → time: \(time)")
        print("   → label: \(label ?? "nil")")
        print("   → repeatFrequency: \(repeatFrequency)")
        print("   → icon: \(icon ?? "nil")")
        print("   → colorHex: \(colorHex ?? "nil")")
        print("   → soundName: \(soundName ?? "nil")")

        // Extract time components
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let timeOfDay = TickerSchedule.TimeOfDay(
            hour: components.hour ?? 0,
            minute: components.minute ?? 0
        )

        // Create schedule based on repeat frequency
        let schedule: TickerSchedule
        if repeatFrequency == .oneTime {
            schedule = .oneTime(date: time)
        } else {
            schedule = repeatFrequency.toTickerSchedule(time: timeOfDay)
        }

        // Create ticker data
        let tickerData = TickerData(
            name: label ?? "Ticker",
            icon: icon,
            colorHex: colorHex
        )

        // Create ticker
        let ticker = Ticker(
            label: label ?? "Ticker",
            isEnabled: true,
            schedule: schedule,
            countdown: nil,
            presentation: TickerPresentation(),
            soundName: soundName,
            tickerData: tickerData
        )

        // Schedule the ticker
        let context = getSharedModelContext()
        let tickerService = Container.shared.tickerService()

        do {
            try await tickerService.scheduleAlarm(from: ticker, context: context)

            // Donate this action to SiriKit for learning
            await donateActionToSiriKit()

            print("   ✅ Ticker creation successful")

            return .result(
                dialog: "Created ticker \"\(ticker.displayName)\" for \(formatTimeForSiri(time))",
                view: TickerCreatedView(ticker: ticker)
            )

        } catch {
            print("   ❌ Ticker creation failed: \(error)")
            throw error
        }
    }

    // MARK: - Simple Creation Path (Deprecated - inlined into perform)

    private func performSimpleCreation() async throws -> some IntentResult {
        // Extract time components
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let timeOfDay = TickerSchedule.TimeOfDay(
            hour: components.hour ?? 0,
            minute: components.minute ?? 0
        )
        
        // Create schedule based on repeat frequency
        let schedule: TickerSchedule
        if repeatFrequency == .oneTime {
            schedule = .oneTime(date: time)
        } else {
            schedule = repeatFrequency.toTickerSchedule(time: timeOfDay)
        }
        
        // Create ticker data
        let tickerData = TickerData(
            name: label ?? "Ticker",
            icon: icon,
            colorHex: colorHex
        )
        
        // Create ticker
        let ticker = Ticker(
            label: label ?? "Ticker",
            isEnabled: true,
            schedule: schedule,
            countdown: nil,
            presentation: TickerPresentation(),
            soundName: soundName,
            tickerData: tickerData
        )
        
        // Schedule the ticker
        let context = getSharedModelContext()
        let tickerService = Container.shared.tickerService()
        
        do {
            try await tickerService.scheduleAlarm(from: ticker, context: context)
            
            // Donate this action to SiriKit for learning
            await donateActionToSiriKit()
            
            print("   ✅ Simple ticker creation successful")
            
            return .result(
                dialog: "Created ticker \"\(ticker.displayName)\" for \(formatTimeForSiri(time))",
                view: TickerCreatedView(ticker: ticker)
            )
            
        } catch {
            print("   ❌ Simple ticker creation failed: \(error)")
            throw error
        }
    }
    
    // MARK: - AI Processor Path

    private func performWithAIProcessor() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // Construct natural language query from parameters
        let aiInput = constructNaturalLanguageQuery()
        print("   → AI input: \(aiInput)")
        
        // Use AI processor with Siri-specific processing
        let aiGenerator = await AITickerGenerator()
        let configuration = try await aiGenerator.generateConfiguration(from: aiInput)
        
        // Create ticker from AI configuration
        let parser = TickerConfigurationParser()
        let ticker = parser.parseToTicker(from: configuration)
        
        // Schedule the ticker
        let context = getSharedModelContext()
        let tickerService = Container.shared.tickerService()
        
        do {
            try await tickerService.scheduleAlarm(from: ticker, context: context)
            
            // Donate this action to SiriKit for learning
            await donateActionToSiriKit()
            
            print("   ✅ AI ticker creation successful")
            
            return .result(
                dialog: "Created ticker \"\(ticker.displayName)\" with AI processing",
                view: TickerCreatedView(ticker: ticker)
            )
            
        } catch {
            print("   ❌ AI ticker creation failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Helper Methods
    
    private func shouldUseAIProcessor() -> Bool {
        // Use AI processor if:
        // 1. Label contains complex scheduling keywords
        // 2. Multiple parameters suggest complex configuration
        // 3. Time suggests recurring pattern
        
        let complexKeywords = ["countdown", "every", "weekday", "weekend", "monthly", "yearly", "interval"]
        let labelText = label?.lowercased() ?? ""
        
        return complexKeywords.contains { labelText.contains($0) } ||
               (icon != nil && colorHex != nil) ||
               repeatFrequency != .oneTime
    }
    
    private func constructNaturalLanguageQuery() -> String {
        var query = "Create a ticker"
        
        if let label = label {
            query += " called \"\(label)\""
        }
        
        let timeString = formatTimeForSiri(time)
        query += " for \(timeString)"
        
        switch repeatFrequency {
        case .daily:
            query += " daily"
        case .weekdays:
            query += " on weekdays"
        case .weekends:
            query += " on weekends"
        case .oneTime:
            break
        }
        
        if let icon = icon {
            query += " with \(icon) icon"
        }
        
        if let colorHex = colorHex {
            query += " in \(colorHex) color"
        }
        
        if let soundName = soundName {
            query += " with \(soundName) sound"
        }
        
        return query
    }
    
    private func formatTimeForSiri(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func getSharedModelContext() -> ModelContext {
        // Get shared ModelContainer for App Groups access
        let schema = Schema([Ticker.self])
        let modelConfiguration: ModelConfiguration
        
        if let sharedURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.m.fig") {
            modelConfiguration = ModelConfiguration(schema: schema, url: sharedURL.appendingPathComponent("Ticker.sqlite"))
        } else {
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return ModelContext(container)
        } catch {
            fatalError("Could not create ModelContext: \(error)")
        }
    }
    
    private func donateActionToSiriKit() async {
        // Donate this action to SiriKit for learning patterns
        do {
            try await self.donate()
            print("✅ Donated action to SiriKit")
        } catch {
            print("⚠️ Failed to donate action to SiriKit: \(error)")
        }
    }
}

// MARK: - Result View

struct TickerCreatedView: View {
    let ticker: Ticker
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("Ticker Created")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack {
                if let tickerData = ticker.tickerData, let icon = tickerData.icon {
                    Image(systemName: icon)
                        .foregroundColor(tickerData.colorHex != nil ? Color(hex: tickerData.colorHex!) : .primary)
                } else {
                    Image(systemName: "alarm")
                        .foregroundColor(.primary)
                }
                
                Text(ticker.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let schedule = ticker.schedule {
                    Text(schedule.displaySummary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
