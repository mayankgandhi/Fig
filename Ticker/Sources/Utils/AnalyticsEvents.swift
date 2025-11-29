//
//  AnalyticsEvents.swift
//  Ticker
//
//  Created by Claude Code
//

import Foundation

/// Analytics events for Ticker app
enum AnalyticsEvents {
    // MARK: - Onboarding
    case onboardingStarted
    case onboardingIntroViewed
    case onboardingAnimationCompleted
    case onboardingPermissionRequested
    case onboardingPermissionGranted
    case onboardingPermissionDenied
    case onboardingCompleted

    // MARK: - Manual Alarm Creation
    case alarmCreateStarted(source: String)
    case alarmTimeSelected(hour: Int, minute: Int)
    case alarmScheduleSelected(scheduleType: String)
    case alarmLabelEdited(labelLength: Int)
    case alarmCountdownConfigured(durationSeconds: Int)
    case alarmIconSelected(iconName: String, colorHex: String)
    case alarmSoundSelected(soundName: String)
    case alarmCreated(scheduleType: String, hasCountdown: Bool, isRecurring: Bool, creationMethod: String)
    case alarmCreationFailed(error: String, scheduleType: String)
    case alarmEdited(alarmId: String, changes: [String])

    // MARK: - AI-Powered Alarm Creation
    case aiAlarmCreateStarted
    case aiInputStarted
    case aiParsingCompleted(inputLength: Int, parseTimeMs: Int, isOffline: Bool = false)
    case aiParsingFailed(error: String, inputLength: Int, isOffline: Bool = false)
    case aiGenerationStarted(inputTextLength: Int)
    case aiGenerationCompleted(inputLength: Int, scheduleType: String, generationTimeMs: Int)
    case aiGenerationFailed(error: String, inputLength: Int)
    case aiAlarmCreated(scheduleType: String, hasCountdown: Bool, creationMethod: String)

    // MARK: - Alarm Management
    case alarmViewed(alarmId: String, scheduleType: String)
    case alarmToggled(alarmId: String, isEnabled: Bool)
    case alarmDeleted(alarmId: String, scheduleType: String, wasEnabled: Bool)
    case alarmStopped(alarmId: String)
    case alarmPaused(alarmId: String)
    case alarmResumed(alarmId: String)
    case alarmCountdownRepeated(alarmId: String)

    // MARK: - Alarm List & Search
    case alarmListViewed(alarmCount: Int)
    case alarmSearched(searchQuery: String, resultsCount: Int)
    case emptyStateViewed(hasOnboarded: Bool)

    // MARK: - Today View
    case todayViewOpened(upcomingAlarmsCount: Int)
    case upcomingAlarmViewed(alarmId: String, timeUntilAlarmSeconds: Int)

    // MARK: - Settings & Subscription
    case settingsOpened
    case subscriptionStatusViewed(isSubscribed: Bool)
    case paywallOpened
    case subscriptionManaged
    case faqOpened
    case roadmapOpened
    case helpSupportOpened
    case aboutOpened
    case deleteAllDataInitiated

    // MARK: - Premium Features
    case premiumFeatureGateShown(feature: String)
    case premiumFeatureUnlocked(feature: String)

    // MARK: - Background Operations
    case appLaunched(alarmCount: Int, enabledAlarmCount: Int)
    case appForegrounded
    case alarmSyncStarted
    case alarmSyncCompleted(syncedCount: Int, orphanedCount: Int, durationMs: Int)
    case alarmRegenerationStarted(tickerId: String)
    case alarmRegenerationCompleted(tickerId: String, generatedCount: Int)
    case alarmRegenerationFailed(tickerId: String, error: String)
    case timezoneChanged(newTimezone: String)

    // MARK: - Permissions
    case permissionPromptShown(context: String)
    case permissionGranted
    case permissionDenied
    case permissionSettingsOpened

    // MARK: - Event Name and Properties
    var eventName: String {
        switch self {
        // Onboarding
        case .onboardingStarted: return "onboarding_started"
        case .onboardingIntroViewed: return "onboarding_intro_viewed"
        case .onboardingAnimationCompleted: return "onboarding_animation_completed"
        case .onboardingPermissionRequested: return "onboarding_permission_requested"
        case .onboardingPermissionGranted: return "onboarding_permission_granted"
        case .onboardingPermissionDenied: return "onboarding_permission_denied"
        case .onboardingCompleted: return "onboarding_completed"

        // Manual Alarm Creation
        case .alarmCreateStarted: return "alarm_create_started"
        case .alarmTimeSelected: return "alarm_time_selected"
        case .alarmScheduleSelected: return "alarm_schedule_selected"
        case .alarmLabelEdited: return "alarm_label_edited"
        case .alarmCountdownConfigured: return "alarm_countdown_configured"
        case .alarmIconSelected: return "alarm_icon_selected"
        case .alarmSoundSelected: return "alarm_sound_selected"
        case .alarmCreated: return "alarm_created"
        case .alarmCreationFailed: return "alarm_creation_failed"
        case .alarmEdited: return "alarm_edited"

        // AI-Powered Alarm Creation
        case .aiAlarmCreateStarted: return "ai_alarm_create_started"
        case .aiInputStarted: return "ai_input_started"
        case .aiParsingCompleted: return "ai_parsing_completed"
        case .aiParsingFailed: return "ai_parsing_failed"
        case .aiGenerationStarted: return "ai_generation_started"
        case .aiGenerationCompleted: return "ai_generation_completed"
        case .aiGenerationFailed: return "ai_generation_failed"
        case .aiAlarmCreated: return "ai_alarm_created"

        // Alarm Management
        case .alarmViewed: return "alarm_viewed"
        case .alarmToggled: return "alarm_toggled"
        case .alarmDeleted: return "alarm_deleted"
        case .alarmStopped: return "alarm_stopped"
        case .alarmPaused: return "alarm_paused"
        case .alarmResumed: return "alarm_resumed"
        case .alarmCountdownRepeated: return "alarm_countdown_repeated"

        // Alarm List & Search
        case .alarmListViewed: return "alarm_list_viewed"
        case .alarmSearched: return "alarm_searched"
        case .emptyStateViewed: return "empty_state_viewed"

        // Today View
        case .todayViewOpened: return "today_view_opened"
        case .upcomingAlarmViewed: return "upcoming_alarm_viewed"

        // Settings & Subscription
        case .settingsOpened: return "settings_opened"
        case .subscriptionStatusViewed: return "subscription_status_viewed"
        case .paywallOpened: return "paywall_opened"
        case .subscriptionManaged: return "subscription_managed"
        case .faqOpened: return "faq_opened"
        case .roadmapOpened: return "roadmap_opened"
        case .helpSupportOpened: return "help_support_opened"
        case .aboutOpened: return "about_opened"
        case .deleteAllDataInitiated: return "delete_all_data_initiated"

        // Premium Features
        case .premiumFeatureGateShown: return "premium_feature_gate_shown"
        case .premiumFeatureUnlocked: return "premium_feature_unlocked"

        // Background Operations
        case .appLaunched: return "app_launched"
        case .appForegrounded: return "app_foregrounded"
        case .alarmSyncStarted: return "alarm_sync_started"
        case .alarmSyncCompleted: return "alarm_sync_completed"
        case .alarmRegenerationStarted: return "alarm_regeneration_started"
        case .alarmRegenerationCompleted: return "alarm_regeneration_completed"
        case .alarmRegenerationFailed: return "alarm_regeneration_failed"
        case .timezoneChanged: return "timezone_changed"

        // Permissions
        case .permissionPromptShown: return "permission_prompt_shown"
        case .permissionGranted: return "permission_granted"
        case .permissionDenied: return "permission_denied"
        case .permissionSettingsOpened: return "permission_settings_opened"
        }
    }

    var properties: [String: Any] {
        switch self {
        // Manual Alarm Creation
        case let .alarmCreateStarted(source):
            return ["source": source]
        case let .alarmTimeSelected(hour, minute):
            return ["hour": hour, "minute": minute]
        case let .alarmScheduleSelected(scheduleType):
            return ["schedule_type": scheduleType]
        case let .alarmLabelEdited(labelLength):
            return ["label_length": labelLength]
        case let .alarmCountdownConfigured(durationSeconds):
            return ["duration_seconds": durationSeconds]
        case let .alarmIconSelected(iconName, colorHex):
            return ["icon_name": iconName, "color_hex": colorHex]
        case let .alarmSoundSelected(soundName):
            return ["sound_name": soundName]
        case let .alarmCreated(scheduleType, hasCountdown, isRecurring, creationMethod):
            return ["schedule_type": scheduleType, "has_countdown": hasCountdown, "is_recurring": isRecurring, "creation_method": creationMethod]
        case let .alarmCreationFailed(error, scheduleType):
            return ["error": error, "schedule_type": scheduleType]
        case let .alarmEdited(alarmId, changes):
            return ["alarm_id": alarmId, "changes": changes]

        // AI-Powered Alarm Creation
        case let .aiParsingCompleted(inputLength, parseTimeMs, isOffline):
            return ["input_length": inputLength, "parse_time_ms": parseTimeMs, "is_offline": isOffline]
        case let .aiParsingFailed(error, inputLength, isOffline):
            return ["error": error, "input_length": inputLength, "is_offline": isOffline]
        case let .aiGenerationStarted(inputTextLength):
            return ["input_text_length": inputTextLength]
        case let .aiGenerationCompleted(inputLength, scheduleType, generationTimeMs):
            return ["input_length": inputLength, "schedule_type": scheduleType, "generation_time_ms": generationTimeMs]
        case let .aiGenerationFailed(error, inputLength):
            return ["error": error, "input_length": inputLength]
        case let .aiAlarmCreated(scheduleType, hasCountdown, creationMethod):
            return ["schedule_type": scheduleType, "has_countdown": hasCountdown, "creation_method": creationMethod]

        // Alarm Management
        case let .alarmViewed(alarmId, scheduleType):
            return ["alarm_id": alarmId, "schedule_type": scheduleType]
        case let .alarmToggled(alarmId, isEnabled):
            return ["alarm_id": alarmId, "is_enabled": isEnabled]
        case let .alarmDeleted(alarmId, scheduleType, wasEnabled):
            return ["alarm_id": alarmId, "schedule_type": scheduleType, "was_enabled": wasEnabled]
        case let .alarmStopped(alarmId):
            return ["alarm_id": alarmId]
        case let .alarmPaused(alarmId):
            return ["alarm_id": alarmId]
        case let .alarmResumed(alarmId):
            return ["alarm_id": alarmId]
        case let .alarmCountdownRepeated(alarmId):
            return ["alarm_id": alarmId]

        // Alarm List & Search
        case let .alarmListViewed(alarmCount):
            return ["alarm_count": alarmCount]
        case let .alarmSearched(searchQuery, resultsCount):
            return ["search_query": searchQuery, "results_count": resultsCount]
        case let .emptyStateViewed(hasOnboarded):
            return ["has_onboarded": hasOnboarded]

        // Today View
        case let .todayViewOpened(upcomingAlarmsCount):
            return ["upcoming_alarms_count": upcomingAlarmsCount]
        case let .upcomingAlarmViewed(alarmId, timeUntilAlarmSeconds):
            return ["alarm_id": alarmId, "time_until_alarm_seconds": timeUntilAlarmSeconds]

        // Settings & Subscription
        case let .subscriptionStatusViewed(isSubscribed):
            return ["is_subscribed": isSubscribed]

        // Premium Features
        case let .premiumFeatureGateShown(feature):
            return ["feature": feature]
        case let .premiumFeatureUnlocked(feature):
            return ["feature": feature]

        // Background Operations
        case let .appLaunched(alarmCount, enabledAlarmCount):
            return ["alarm_count": alarmCount, "enabled_alarm_count": enabledAlarmCount]
        case let .alarmSyncCompleted(syncedCount, orphanedCount, durationMs):
            return ["synced_count": syncedCount, "orphaned_count": orphanedCount, "duration_ms": durationMs]
        case let .alarmRegenerationStarted(tickerId):
            return ["ticker_id": tickerId]
        case let .alarmRegenerationCompleted(tickerId, generatedCount):
            return ["ticker_id": tickerId, "generated_count": generatedCount]
        case let .alarmRegenerationFailed(tickerId, error):
            return ["ticker_id": tickerId, "error": error]
        case let .timezoneChanged(newTimezone):
            return ["new_timezone": newTimezone]

        // Permissions
        case let .permissionPromptShown(context):
            return ["context": context]

        // Events without properties
        default:
            return [:]
        }
    }
}
