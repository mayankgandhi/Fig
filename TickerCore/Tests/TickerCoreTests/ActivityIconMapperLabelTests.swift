//
//  ActivityIconMapperLabelTests.swift
//  TickerCoreTests
//
//  Regression cover for C19: generated labels kept their schedule tokens.
//

import XCTest
import NaturalLanguage
@testable import TickerCore

/// The label Fig derives from natural language must never contain the schedule
/// it was parsed out of. `TickerConfigurationParserTests` pins the exact strings;
/// these tests pin the *promise*, so they keep holding if Apple's tokeniser
/// changes its output again.
final class ActivityIconMapperLabelTests: XCTestCase {

    private let mapper = ActivityIconMapper()

    /// Inputs whose activity words are not in `activityMappings`, so they reach
    /// the label extractor rather than a keyword or semantic match.
    private let scheduleInputs = [
        "Every 3 hours starting at 9 am remind me to stretch.",
        "Starting at 8:15 am remind me every 45 minutes to stretch and breathe.",
        "Starting tomorrow at 10 am remind me every 2 days to water the plants.",
        "Remind me every 2 weeks at 10 am to review OKRs.",
        "Schedule the status report monthly on the first Monday at 8 am.",
        "Schedule yearly dentist check at 2 pm.",
        "In 2 hours remind me to drink water.",
        "Remind me soon to send the follow up email.",
        "Remind me at 8 pm with a 30 minute countdown to start cooking."
    ]

    // MARK: - The promise

    func test_mapActivity_labelNeverContainsDigits() {
        for input in scheduleInputs {
            let label = mapper.mapActivity(from: input).label
            XCTAssertFalse(
                label.contains(where: \.isNumber),
                "Label for \"\(input)\" kept a schedule value: \"\(label)\""
            )
        }
    }

    func test_mapActivity_labelNeverContainsScheduleOrFunctionWords() {
        // Words that are always schedule or grammar, never the activity.
        let forbidden: Set<String> = [
            "am", "pm", "at", "every", "each", "remind", "me", "to", "the",
            "on", "starting", "monthly", "yearly", "schedule", "countdown",
            "soon", "with", "in", "and", "hours", "minutes", "days", "weeks",
            "tomorrow", "monday", "first"
        ]

        for input in scheduleInputs {
            let label = mapper.mapActivity(from: input).label
            let words = Set(label.lowercased().components(separatedBy: " "))
            let leaked = words.intersection(forbidden)
            XCTAssertTrue(
                leaked.isEmpty,
                "Label for \"\(input)\" leaked \(leaked.sorted()): \"\(label)\""
            )
        }
    }

    func test_mapActivity_labelIsNeverEmptyAndHasNoTrailingPunctuation() {
        for input in scheduleInputs {
            let label = mapper.mapActivity(from: input).label
            XCTAssertFalse(label.isEmpty, "Empty label for \"\(input)\"")
            XCTAssertFalse(
                label.hasSuffix(".") || label.hasSuffix(","),
                "Label for \"\(input)\" kept sentence punctuation: \"\(label)\""
            )
        }
    }

    // MARK: - Why the deterministic path has to be correct

    /// Documents the platform fact behind C19 rather than asserting it: the
    /// extractor must satisfy the tests above whether or not `lexicalClass` is
    /// offered. On the iOS 27 simulator it is not — `availableTagSchemes` is
    /// only `[Language, Script, TokenType, Lemma]`, so every word tags as
    /// `OtherWord`, the part-of-speech path yields nothing, and the
    /// deterministic extractor produces the user-visible title.
    func test_lexicalClassAvailability_isRecordedNotRequired() {
        let schemes = NLTagger.availableTagSchemes(for: .word, language: .english)
        print("lexicalClass available: \(schemes.contains(.lexicalClass)) — schemes: \(schemes.map(\.rawValue))")
    }
}
