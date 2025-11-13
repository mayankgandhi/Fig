import SwiftData
import Combine
import Foundation

/// Observes SwiftData saves and triggers UI refresh across all contexts
/// This ensures that changes made in one ModelContext are reflected in views using other contexts
@MainActor
public final class ModelContextObserver: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    public init() {
        // Listen for save notifications from ANY ModelContext
        NotificationCenter.default.publisher(for: ModelContext.didSave)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                // Trigger objectWillChange to refresh any views observing this
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}
