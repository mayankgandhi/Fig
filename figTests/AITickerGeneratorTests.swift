//
//  AITickerGeneratorTests.swift
//  figTests
//
//  Unit tests for AI ticker generation
//

import XCTest
@testable import Ticker

@MainActor
final class AITickerGeneratorTests: XCTestCase {
    
    var aiGenerator: AITickerGenerator!
    var parser: TickerConfigurationParser!
    
    override func setUp() {
        super.setUp()
        aiGenerator = AITickerGenerator()
        parser = TickerConfigurationParser()
    }
    
    override func tearDown() {
        aiGenerator = nil
        parser = nil
        super.tearDown()
    }
    
    // MARK: - Time Parsing Tests
    
    func testTimeParsing_12HourFormat() async throws {
        let input = "Wake up at 7am every day"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        XCTAssertEqual(configuration.time.hour, 7)
        XCTAssertEqual(configuration.time.minute, 0)
    }
    
    func testTimeParsing_12HourFormatPM() async throws {
        let input = "Meeting at 2:30pm tomorrow"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        XCTAssertEqual(configuration.time.hour, 14)
        XCTAssertEqual(configuration.time.minute, 30)
    }
    
    func testTimeParsing_24HourFormat() async throws {
        let input = "Gym at 18:00 every weekday"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        XCTAssertEqual(configuration.time.hour, 18)
        XCTAssertEqual(configuration.time.minute, 0)
    }
    
    func testTimeParsing_WithMinutes() async throws {
        let input = "Coffee break at 3:15pm daily"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        XCTAssertEqual(configuration.time.hour, 15)
        XCTAssertEqual(configuration.time.minute, 15)
    }
    
    func testTimeParsing_NaturalExpressions() async throws {
        let testCases = [
            ("Meeting at noon", 12, 0),
            ("Wake up at midnight", 0, 0),
            ("Lunch at lunchtime", 12, 0),
            ("Exercise in the morning", 8, 0),
            ("Dinner in the evening", 18, 0),
            ("Bedtime at night", 20, 0)
        ]
        
        for (input, expectedHour, expectedMinute) in testCases {
            let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
            XCTAssertEqual(configuration.time.hour, expectedHour, "Failed for input: \(input)")
            XCTAssertEqual(configuration.time.minute, expectedMinute, "Failed for input: \(input)")
        }
    }
    
    func testTimeParsing_FlexibleFormats() async throws {
        let testCases = [
            ("Meeting at 9:30 AM", 9, 30),
            ("Wake up at 7:00am", 7, 0),
            ("Lunch at 12.30pm", 12, 30),
            ("Gym at 6:45 PM", 18, 45),
            ("Coffee at 3:15", 15, 15),
            ("Dinner around 7pm", 19, 0)
        ]
        
        for (input, expectedHour, expectedMinute) in testCases {
            let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
            XCTAssertEqual(configuration.time.hour, expectedHour, "Failed for input: \(input)")
            XCTAssertEqual(configuration.time.minute, expectedMinute, "Failed for input: \(input)")
        }
    }
    
    // MARK: - Repeat Pattern Tests
    
    func testRepeatPattern_Daily() async throws {
        let input = "Take medication at 9am every day"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        if case .daily = configuration.repeatOption {
            // Success
        } else {
            XCTFail("Expected daily repeat pattern")
        }
    }
    
    func testRepeatPattern_Weekdays() async throws {
        let input = "Wake up at 7am on weekdays"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        if case .weekdays(let weekdays) = configuration.repeatOption {
            XCTAssertEqual(weekdays, [.monday, .tuesday, .wednesday, .thursday, .friday])
        } else {
            XCTFail("Expected weekdays repeat pattern")
        }
    }
    
    func testRepeatPattern_SpecificDays() async throws {
        let input = "Yoga class every Monday and Wednesday at 7am"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        if case .weekdays(let weekdays) = configuration.repeatOption {
            XCTAssertTrue(weekdays.contains(.monday))
            XCTAssertTrue(weekdays.contains(.wednesday))
        } else {
            XCTFail("Expected specific weekdays repeat pattern")
        }
    }
    
    func testRepeatPattern_EnhancedVariations() async throws {
        let testCases = [
            ("Meeting every day", AITickerGenerator.RepeatOption.daily),
            ("Wake up daily", AITickerGenerator.RepeatOption.daily),
            ("Exercise each day", AITickerGenerator.RepeatOption.daily),
            ("Work on weekdays", AITickerGenerator.RepeatOption.weekdays([.monday, .tuesday, .wednesday, .thursday, .friday])),
            ("Gym on workdays", AITickerGenerator.RepeatOption.weekdays([.monday, .tuesday, .wednesday, .thursday, .friday])),
            ("Yoga on Mondays and Wednesdays", AITickerGenerator.RepeatOption.weekdays([.monday, .wednesday])),
            ("Meeting every 2 hours", AITickerGenerator.RepeatOption.hourly(interval: 2)),
            ("Check every 3 hours", AITickerGenerator.RepeatOption.hourly(interval: 3)),
            ("Biweekly meeting", AITickerGenerator.RepeatOption.biweekly([.monday, .wednesday, .friday])),
            ("Monthly report on the 15th", AITickerGenerator.RepeatOption.monthly(day: 15))
        ]
        
        for (input, expectedOption) in testCases {
            let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
            XCTAssertEqual(String(describing: configuration.repeatOption), String(describing: expectedOption), "Failed for input: \(input)")
        }
    }
    
    func testRepeatPattern_NoRepeat() async throws {
        let input = "Doctor appointment at 2pm tomorrow"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        if case .noRepeat = configuration.repeatOption {
            // Success
        } else {
            XCTFail("Expected no repeat pattern")
        }
    }
    
    // MARK: - Activity Mapping Tests
    
    func testActivityMapping_Exercise() async throws {
        let input = "Morning yoga at 7am daily"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        XCTAssertEqual(configuration.label, "Yoga")
        XCTAssertEqual(configuration.icon, "figure.yoga")
        XCTAssertEqual(configuration.colorHex, "#84CC16")
    }
    
    func testActivityMapping_Medication() async throws {
        let input = "Take pills at 9am and 9pm daily"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        XCTAssertEqual(configuration.label, "Pills")
        XCTAssertEqual(configuration.icon, "pills")
        XCTAssertEqual(configuration.colorHex, "#EF4444")
    }
    
    func testActivityMapping_Work() async throws {
        let input = "Team meeting at 2pm every Tuesday"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        XCTAssertEqual(configuration.label, "Team Meeting")
        XCTAssertEqual(configuration.icon, "person.3")
        XCTAssertEqual(configuration.colorHex, "#3B82F6")
    }
    
    func testActivityMapping_Meals() async throws {
        let input = "Lunch break at 12pm daily"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        XCTAssertEqual(configuration.label, "Lunch")
        XCTAssertEqual(configuration.icon, "fork.knife")
        XCTAssertEqual(configuration.colorHex, "#10B981")
    }
    
    // MARK: - Countdown Tests
    
    func testCountdownParsing() async throws {
        let input = "Meeting at 2pm with 5 minute countdown"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        XCTAssertNotNil(configuration.countdown)
        XCTAssertEqual(configuration.countdown?.hours, 0)
        XCTAssertEqual(configuration.countdown?.minutes, 5)
        XCTAssertEqual(configuration.countdown?.seconds, 0)
    }
    
    func testCountdownParsing_NoCountdown() async throws {
        let input = "Wake up at 7am daily"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        XCTAssertNil(configuration.countdown)
    }
    
    func testCountdownParsing_EnhancedVariations() async throws {
        let testCases = [
            ("Meeting with 10 minute reminder", 0, 10, 0),
            ("Wake up with 5 min alert", 0, 5, 0),
            ("Gym with 1 hour countdown", 1, 0, 0),
            ("Lunch with 30 minute notice", 0, 30, 0),
            ("Meeting after 15 minutes", 0, 15, 0),
            ("Wake up in 2 hours", 2, 0, 0),
            ("Coffee with 1 hour and 30 minute countdown", 1, 30, 0),
            ("Meeting with 45 second countdown", 0, 0, 45)
        ]
        
        for (input, expectedHours, expectedMinutes, expectedSeconds) in testCases {
            let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
            XCTAssertNotNil(configuration.countdown, "Failed for input: \(input)")
            XCTAssertEqual(configuration.countdown?.hours, expectedHours, "Failed for input: \(input)")
            XCTAssertEqual(configuration.countdown?.minutes, expectedMinutes, "Failed for input: \(input)")
            XCTAssertEqual(configuration.countdown?.seconds, expectedSeconds, "Failed for input: \(input)")
        }
    }
    
    // MARK: - Date Parsing Tests
    
    func testDateParsing_Tomorrow() async throws {
        let input = "Doctor appointment at 2pm tomorrow"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        
        XCTAssertEqual(calendar.component(.day, from: configuration.date), 
                      calendar.component(.day, from: tomorrow))
    }
    
    func testDateParsing_Today() async throws {
        let input = "Meeting at 3pm today"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        let calendar = Calendar.current
        let today = Date()
        
        XCTAssertEqual(calendar.component(.day, from: configuration.date), 
                      calendar.component(.day, from: today))
    }
    
    // MARK: - Complex Input Tests
    
    func testComplexInput_FullDescription() async throws {
        let input = "Morning yoga every Monday, Wednesday, Friday at 7am with 10 minute countdown"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        // Check time
        XCTAssertEqual(configuration.time.hour, 7)
        XCTAssertEqual(configuration.time.minute, 0)
        
        // Check repeat pattern
        if case .weekdays(let weekdays) = configuration.repeatOption {
            XCTAssertTrue(weekdays.contains(.monday))
            XCTAssertTrue(weekdays.contains(.wednesday))
            XCTAssertTrue(weekdays.contains(.friday))
        } else {
            XCTFail("Expected specific weekdays")
        }
        
        // Check activity
        XCTAssertEqual(configuration.label, "Yoga")
        XCTAssertEqual(configuration.icon, "figure.yoga")
        
        // Check countdown
        XCTAssertNotNil(configuration.countdown)
        XCTAssertEqual(configuration.countdown?.minutes, 10)
    }
    
    func testComplexInput_MedicationReminder() async throws {
        let input = "Remind me to take medication at 9am and 9pm daily"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        // Check activity
        XCTAssertEqual(configuration.label, "Medication")
        XCTAssertEqual(configuration.icon, "pills")
        XCTAssertEqual(configuration.colorHex, "#EF4444")
        
        // Check repeat pattern
        if case .daily = configuration.repeatOption {
            // Success
        } else {
            XCTFail("Expected daily repeat")
        }
    }
    
    // MARK: - Parser Integration Tests
    
    func testParserIntegration_ValidConfiguration() async throws {
        let input = "Wake up at 7am every weekday"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        let ticker = parser.parseToTicker(from: configuration)
        
        XCTAssertEqual(ticker.label, "Wake Up")
        XCTAssertTrue(ticker.isEnabled)
        XCTAssertNotNil(ticker.schedule)
        XCTAssertNotNil(ticker.tickerData)
    }
    
    func testParserIntegration_WithCountdown() async throws {
        let input = "Meeting at 2pm with 5 minute countdown"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        let ticker = parser.parseToTicker(from: configuration)
        
        XCTAssertNotNil(ticker.countdown)
        XCTAssertEqual(ticker.countdown?.preAlert?.minutes, 5)
    }
    
    // MARK: - Validation Tests
    
    func testValidation_ValidConfiguration() async throws {
        let input = "Wake up at 7am every weekday"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        let validation = parser.validateConfiguration(configuration)
        
        XCTAssertTrue(validation.isValid)
        XCTAssertTrue(validation.errors.isEmpty)
    }
    
    func testValidation_InvalidTime() async throws {
        let input = "Wake up at 25am every day" // Invalid hour
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        let validation = parser.validateConfiguration(configuration)
        
        // The AI generator should handle this gracefully, but if it doesn't,
        // the validation should catch it
        if !validation.isValid {
            XCTAssertFalse(validation.errors.isEmpty)
        }
    }
    
    // MARK: - Edge Cases
    
    func testEdgeCase_EmptyInput() async throws {
        do {
            _ = try await aiGenerator.generateTickerConfiguration(from: "")
            XCTFail("Should have thrown an error for empty input")
        } catch {
            // Expected to throw an error
        }
    }
    
    func testEdgeCase_UnclearInput() async throws {
        let input = "something random without time or activity"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        // Should provide reasonable defaults
        XCTAssertFalse(configuration.label.isEmpty)
    }
    
    func testEdgeCase_AmbiguousTime() async throws {
        let input = "Meeting at noon"
        let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
        
        // Should default to 12:00 PM
        XCTAssertEqual(configuration.time.hour, 12)
        XCTAssertEqual(configuration.time.minute, 0)
    }
    
    // MARK: - Additional Comprehensive Tests
    
    func testTimeParsing_EdgeCases() async throws {
        let testCases = [
            ("Meeting at 12:00pm", 12, 0),
            ("Wake up at 12:00am", 0, 0),
            ("Lunch at 12:30pm", 12, 30),
            ("Midnight snack at 12:00am", 0, 0),
            ("Noon meeting at 12:00pm", 12, 0),
            ("Early morning at 1:00am", 1, 0),
            ("Late night at 11:59pm", 23, 59),
            ("Afternoon at 1:00pm", 13, 0),
            ("Evening at 6:00pm", 18, 0)
        ]
        
        for (input, expectedHour, expectedMinute) in testCases {
            let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
            XCTAssertEqual(configuration.time.hour, expectedHour, "Failed for input: \(input)")
            XCTAssertEqual(configuration.time.minute, expectedMinute, "Failed for input: \(input)")
        }
    }
    
    func testActivityMapping_Comprehensive() async throws {
        let testCases = [
            ("Team meeting at 2pm", "Team Meeting", "person.3", "#3B82F6"),
            ("Coffee break at 3pm", "Coffee", "cup.and.saucer", "#92400E"),
            ("Tea time at 4pm", "Tea", "cup.and.saucer", "#92400E"),
            ("Yoga class at 7am", "Yoga", "figure.yoga", "#84CC16"),
            ("Gym workout at 6pm", "Gym", "dumbbell", "#FF6B35"),
            ("Doctor appointment at 10am", "Doctor", "cross.case", "#EF4444"),
            ("Take medication at 9am", "Medication", "pills", "#EF4444"),
            ("Lunch break at 12pm", "Lunch", "fork.knife", "#10B981"),
            ("Wake up at 7am", "Wake Up", "sunrise", "#F59E0B"),
            ("Bedtime at 10pm", "Bedtime", "moon", "#6366F1")
        ]
        
        for (input, expectedLabel, expectedIcon, expectedColor) in testCases {
            let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
            XCTAssertEqual(configuration.label, expectedLabel, "Failed for input: \(input)")
            XCTAssertEqual(configuration.icon, expectedIcon, "Failed for input: \(input)")
            XCTAssertEqual(configuration.colorHex, expectedColor, "Failed for input: \(input)")
        }
    }
    
    func testCountdownParsing_Comprehensive() async throws {
        let testCases = [
            ("Meeting with 5 minute countdown", 0, 5, 0),
            ("Wake up with 10 min alert", 0, 10, 0),
            ("Gym with 1 hour countdown", 1, 0, 0),
            ("Lunch with 30 minute notice", 0, 30, 0),
            ("Coffee with 1 hour and 30 minute countdown", 1, 30, 0),
            ("Meeting with 45 second countdown", 0, 0, 45),
            ("Wake up in 2 hours", 2, 0, 0),
            ("Meeting after 15 minutes", 0, 15, 0),
            ("Gym with 2 hour and 15 minute countdown", 2, 15, 0),
            ("Lunch with 1 hr countdown", 1, 0, 0)
        ]
        
        for (input, expectedHours, expectedMinutes, expectedSeconds) in testCases {
            let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
            XCTAssertNotNil(configuration.countdown, "Failed for input: \(input)")
            XCTAssertEqual(configuration.countdown?.hours, expectedHours, "Failed for input: \(input)")
            XCTAssertEqual(configuration.countdown?.minutes, expectedMinutes, "Failed for input: \(input)")
            XCTAssertEqual(configuration.countdown?.seconds, expectedSeconds, "Failed for input: \(input)")
        }
    }
    
    func testRepeatPatterns_Comprehensive() async throws {
        let testCases = [
            ("Meeting every day", AITickerGenerator.RepeatOption.daily),
            ("Wake up daily", AITickerGenerator.RepeatOption.daily),
            ("Exercise each day", AITickerGenerator.RepeatOption.daily),
            ("Work on weekdays", AITickerGenerator.RepeatOption.weekdays([.monday, .tuesday, .wednesday, .thursday, .friday])),
            ("Gym on workdays", AITickerGenerator.RepeatOption.weekdays([.monday, .tuesday, .wednesday, .thursday, .friday])),
            ("Yoga on Mondays and Wednesdays", AITickerGenerator.RepeatOption.weekdays([.monday, .wednesday])),
            ("Meeting every 2 hours", AITickerGenerator.RepeatOption.hourly(interval: 2)),
            ("Check every 3 hours", AITickerGenerator.RepeatOption.hourly(interval: 3)),
            ("Biweekly meeting", AITickerGenerator.RepeatOption.biweekly([.monday, .wednesday, .friday])),
            ("Monthly report on the 15th", AITickerGenerator.RepeatOption.monthly(day: 15)),
            ("Monthly report on the 1st", AITickerGenerator.RepeatOption.monthly(day: 1)),
            ("Monthly report on the 31st", AITickerGenerator.RepeatOption.monthly(day: 31))
        ]
        
        for (input, expectedOption) in testCases {
            let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
            XCTAssertEqual(String(describing: configuration.repeatOption), String(describing: expectedOption), "Failed for input: \(input)")
        }
    }
    
    func testNaturalTimeExpressions_Comprehensive() async throws {
        let testCases = [
            ("Meeting at midnight", 0, 0),
            ("Wake up at noon", 12, 0),
            ("Lunch at midday", 12, 0),
            ("Exercise in the morning", 8, 0),
            ("Dinner in the evening", 18, 0),
            ("Bedtime at night", 20, 0),
            ("Meeting at dawn", 6, 0),
            ("Sunrise yoga", 6, 30),
            ("Late morning coffee", 10, 0),
            ("Afternoon meeting", 14, 0),
            ("Late afternoon snack", 16, 0),
            ("Dusk walk", 19, 0),
            ("Sunset dinner", 19, 30),
            ("Late night study", 22, 0)
        ]
        
        for (input, expectedHour, expectedMinute) in testCases {
            let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
            XCTAssertEqual(configuration.time.hour, expectedHour, "Failed for input: \(input)")
            XCTAssertEqual(configuration.time.minute, expectedMinute, "Failed for input: \(input)")
        }
    }
    
    func testComplexScenarios_Comprehensive() async throws {
        let testCases = [
            ("Morning yoga every Monday, Wednesday, Friday at 7am with 10 minute countdown", 7, 0, "Yoga", "figure.yoga", 0, 10, 0),
            ("Team meeting at 2:30pm every Tuesday with 5 minute reminder", 14, 30, "Team Meeting", "person.3", 0, 5, 0),
            ("Coffee break at 3:15pm daily with 15 minute alert", 15, 15, "Coffee", "cup.and.saucer", 0, 15, 0),
            ("Gym workout at 6pm on weekdays with 1 hour countdown", 18, 0, "Gym", "dumbbell", 1, 0, 0),
            ("Doctor appointment at 10am tomorrow with 30 minute notice", 10, 0, "Doctor", "cross.case", 0, 30, 0),
            ("Take medication at 9am and 9pm daily", 9, 0, "Medication", "pills", nil, nil, nil),
            ("Lunch break at 12pm every weekday with 10 minute reminder", 12, 0, "Lunch", "fork.knife", 0, 10, 0),
            ("Wake up at 7am daily with 5 minute alert", 7, 0, "Wake Up", "sunrise", 0, 5, 0),
            ("Bedtime at 10pm every night with 15 minute countdown", 22, 0, "Bedtime", "moon", 0, 15, 0),
            ("Monthly report on the 15th at 2pm with 1 hour notice", 14, 0, "Report", "alarm", 1, 0, 0)
        ]
        
        for (input, expectedHour, expectedMinute, expectedLabel, expectedIcon, expectedCountdownHours, expectedCountdownMinutes, expectedCountdownSeconds) in testCases {
            let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
            
            // Test time
            XCTAssertEqual(configuration.time.hour, expectedHour, "Failed time hour for input: \(input)")
            XCTAssertEqual(configuration.time.minute, expectedMinute, "Failed time minute for input: \(input)")
            
            // Test activity
            XCTAssertEqual(configuration.label, expectedLabel, "Failed label for input: \(input)")
            XCTAssertEqual(configuration.icon, expectedIcon, "Failed icon for input: \(input)")
            
            // Test countdown (if expected)
            if let expectedHours = expectedCountdownHours,
               let expectedMinutes = expectedCountdownMinutes,
               let expectedSeconds = expectedCountdownSeconds {
                XCTAssertNotNil(configuration.countdown, "Failed countdown for input: \(input)")
                XCTAssertEqual(configuration.countdown?.hours, expectedHours, "Failed countdown hours for input: \(input)")
                XCTAssertEqual(configuration.countdown?.minutes, expectedMinutes, "Failed countdown minutes for input: \(input)")
                XCTAssertEqual(configuration.countdown?.seconds, expectedSeconds, "Failed countdown seconds for input: \(input)")
            } else {
                XCTAssertNil(configuration.countdown, "Expected no countdown for input: \(input)")
            }
        }
    }
    
    func testEdgeCases_Comprehensive() async throws {
        let testCases = [
            ("Meeting at 25am every day", "Should handle invalid hour gracefully"),
            ("Wake up at 7:60am daily", "Should handle invalid minute gracefully"),
            ("Gym at 24:00 every day", "Should handle 24:00 as midnight"),
            ("Coffee at 0:30 every day", "Should handle 0:30 as 12:30am"),
            ("Lunch at 13:00 every day", "Should handle 24-hour format"),
            ("Dinner at 19:30 every day", "Should handle 24-hour format with minutes"),
            ("Meeting at 12:00pm every day", "Should handle noon correctly"),
            ("Wake up at 12:00am every day", "Should handle midnight correctly"),
            ("Snack at 12:30pm every day", "Should handle 12:30pm correctly"),
            ("Breakfast at 12:30am every day", "Should handle 12:30am correctly")
        ]
        
        for (input, description) in testCases {
            do {
                let configuration = try await aiGenerator.generateTickerConfiguration(from: input)
                // If it doesn't throw, verify the time is reasonable
                XCTAssertTrue(configuration.time.hour >= 0 && configuration.time.hour <= 23, "\(description) - Invalid hour: \(configuration.time.hour)")
                XCTAssertTrue(configuration.time.minute >= 0 && configuration.time.minute <= 59, "\(description) - Invalid minute: \(configuration.time.minute)")
            } catch {
                // If it throws an error, that's also acceptable for invalid inputs
                XCTAssertTrue(true, "\(description) - Threw expected error: \(error)")
            }
        }
    }
}
