//
//  AISessionManager.swift
//  TickerCore
//
//  Manages LanguageModelSession lifecycle for AI-powered ticker generation
//

import Foundation
import FoundationModels

/// Singleton manager for handling LanguageModelSession lifecycle
/// Extracted from AITickerGenerator to separate concerns and enable reuse across contexts
@MainActor
public final class AISessionManager {

    /// Shared singleton instance
    public static let shared = AISessionManager()

    // MARK: - Private Properties

    private var languageModelSession: LanguageModelSession?
    private var sessionPrewarmed = false
    private let foundationModelsParser = FoundationModelsParser()

    // MARK: - Public Properties

    /// Whether Foundation Models are available for use
    public private(set) var isFoundationModelsAvailable = false

    // MARK: - Initialization

    private init() {
        // Private init for singleton
    }

    // MARK: - Session Lifecycle

    /// Prepares and initializes the language model session
    /// Call this when the view appears or before using AI features
    public func prepare() async {
        guard languageModelSession == nil else { return }
        await checkAvailabilityAndInitialize()
    }

    /// Cleans up the session and releases resources
    /// Call this when the view disappears or is done with AI features
    public func cleanup() {
        languageModelSession = nil
        sessionPrewarmed = false
    }

    /// Returns the current language model session if available
    internal func getSession() -> LanguageModelSession? {
        return languageModelSession
    }

    // MARK: - Private Methods

    private func checkAvailabilityAndInitialize() async {
        // Foundation Models code is currently disabled
        // When re-enabled, this will check availability and create/prewarm the session

        // Commented out original implementation:
        //        let model = SystemLanguageModel.default
        //
        //        switch model.availability {
        //            case .available:
        //                isFoundationModelsAvailable = true
        //
        //                // Create session using FoundationModelsParser
        //                languageModelSession = foundationModelsParser.createSession(model: model)
        //
        //                // Prewarm the session with the instruction prefix for better first-response performance
        //                if !sessionPrewarmed {
        //                    if let session = languageModelSession {
        //                        try? await foundationModelsParser.prewarmSession(session: session)
        //                        sessionPrewarmed = true
        //                    }
        //                }
        //
        //            case .unavailable(let reason):
        //                isFoundationModelsAvailable = false
        //        }

        // Current behavior: Foundation Models are unavailable
        isFoundationModelsAvailable = false
    }
}
