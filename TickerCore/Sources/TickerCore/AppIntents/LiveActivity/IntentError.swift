import Foundation

/// Errors thrown by Live Activity intents
@available(iOS 26.0, *)
public enum IntentError: LocalizedError {
    case invalidAlarmID

    public var errorDescription: String? {
        switch self {
        case .invalidAlarmID:
            return "Invalid alarm identifier"
        }
    }
}
