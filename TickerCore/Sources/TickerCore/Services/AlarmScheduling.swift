//
//  AlarmScheduling.swift
//  TickerCore
//
//  A protocol seam over AlarmKit's AlarmManager.
//
//  `AlarmManager` is `@_hasMissingDesignatedInitializers` and `Alarm` cannot be
//  constructed, so neither can be faked in a test. The practical consequence was
//  that the existing mock (`MockAlarmStateManager`) fell through to the *real*
//  `AlarmManager.shared` whenever its `mockAlarms` array was empty — which it
//  always was — so roughly sixty synchronization tests ran against whatever the
//  host simulator happened to hold, and every error path in the alarm pipeline
//  was untestable.
//
//  Production code depends on this protocol; `AlarmManager` conforms to it for
//  free because the member names match exactly.
//

import Foundation
import AlarmKit

@available(iOS 26.0, *)
public protocol AlarmScheduling: AnyObject {

    /// Alarms currently armed in AlarmKit.
    var alarms: [Alarm] { get throws }

    var authorizationState: AlarmManager.AuthorizationState { get }

    func requestAuthorization() async throws -> AlarmManager.AuthorizationState

    @discardableResult
    func schedule(
        id: UUID,
        configuration: AlarmManager.AlarmConfiguration<TickerData>
    ) async throws -> Alarm

    func countdown(id: UUID) throws
    func cancel(id: UUID) throws
    func stop(id: UUID) throws
    func pause(id: UUID) throws
    func resume(id: UUID) throws
}

/// Conformance is satisfied entirely by AlarmManager's existing members; the
/// generic `schedule<Metadata>` witnesses the `TickerData`-specific requirement.
@available(iOS 26.0, *)
extension AlarmManager: AlarmScheduling {}
