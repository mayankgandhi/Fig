//
//  SoundPickerViewModel.swift
//  fig
//
//  Manages alarm sound selection and preview
//

import Foundation
import AVFoundation

// MARK: - AlarmSound Model

struct AlarmSound: Identifiable, Hashable {
    let id: String?  // nil = system default
    let name: String
    let fileName: String?  // Full filename including extension (e.g., "gentle-chime.caf")

    var displayName: String {
        name
    }
}

// MARK: - SoundPickerViewModel

@Observable
final class SoundPickerViewModel {
    var selectedSound: String? = nil  // nil = system default
    private var audioPlayer: AVAudioPlayer?

    // MARK: - Available Sounds

    let availableSounds: [AlarmSound] = [
        AlarmSound(id: nil, name: "Default", fileName: nil),
        AlarmSound(id: "gentle-chime", name: "Gentle Chime", fileName: "gentle-chime.caf"),
        AlarmSound(id: "radar", name: "Radar", fileName: "radar.caf"),
        AlarmSound(id: "digital", name: "Digital", fileName: "digital.caf"),
        AlarmSound(id: "bell", name: "Bell", fileName: "bell.caf"),
        AlarmSound(id: "marimba", name: "Marimba", fileName: "marimba.caf"),
        AlarmSound(id: "ascending", name: "Ascending", fileName: "ascending.caf")
    ]

    // MARK: - Computed Properties

    var displayText: String {
        if let selectedId = selectedSound,
           let sound = availableSounds.first(where: { $0.id == selectedId }) {
            return sound.displayName
        }
        return "Default"
    }

    var hasValue: Bool {
        selectedSound != nil
    }

    var selectedSoundObject: AlarmSound? {
        availableSounds.first { $0.id == selectedSound }
    }

    // MARK: - Methods

    func selectSound(_ soundId: String?) {
        selectedSound = soundId
        stopPreview()
    }

    func previewSound(_ fileName: String?) {
        stopPreview()

        guard let fileName = fileName else {
            // Play system default alarm sound
            playSystemSound()
            return
        }

        // Remove extension for Bundle lookup
        let fileNameWithoutExtension = fileName.replacingOccurrences(of: ".caf", with: "")

        guard let url = Bundle.main.url(forResource: fileNameWithoutExtension, withExtension: "caf") else {
            print("⚠️ Sound file not found: \(fileName)")
            // Fallback to system sound
            playSystemSound()
            return
        }

        do {
            // Configure audio session for playback
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("⚠️ Error playing sound: \(error)")
            // Fallback to system sound
            playSystemSound()
        }
    }

    func stopPreview() {
        audioPlayer?.stop()
        audioPlayer = nil
    }

    func reset() {
        selectedSound = nil
        stopPreview()
    }

    // MARK: - Private Methods

    private func playSystemSound() {
        // Play system alarm sound (sound ID 1005 is a typical alarm sound)
        AudioServicesPlaySystemSound(1005)
    }
}
