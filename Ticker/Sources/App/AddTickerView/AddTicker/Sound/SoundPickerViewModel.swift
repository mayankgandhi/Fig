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
    var selectedSound: AlarmSound? = nil  // nil = system default
    var isPlaying: Bool = false
    var currentlyPlayingSound: String? = nil
    private var audioPlayer: AVAudioPlayer?
    
    // MARK: - Available Sounds
    
    let availableSounds: [AlarmSound] = [
        AlarmSound(id: "alarm_clock_short", name: "Alarm Clock Short", fileName: "alarm-clock-short.mp3"),
        AlarmSound(id: "classic_digital_alarm", name: "Classic Digital Alarm", fileName: "classic_digital_alarm.wav"),
        AlarmSound(id: "lofi_alarm_clock", name: "Lo-Fi Alarm Clock", fileName: "lo-fi-alarm-clock.mp3"),
        AlarmSound(id: "magical_tone", name: "Magical Tone", fileName: "magical-tone-soft-fantasy.mp3"),
        AlarmSound(id: "casino_jackpot", name: "Casino Jackpot", fileName: "mixkit-casino-jackpot-alarm-and-coins-1991.wav"),
        AlarmSound(id: "happy_countdown", name: "Happy Countdown", fileName: "mixkit-children-happy-countdown-923.wav"),
        AlarmSound(id: "marimba_ringtone", name: "Marimba Ringtone", fileName: "mixkit-marimba-ringtone-1359.wav"),
        AlarmSound(id: "retro_game_alarm", name: "Retro Game Alarm", fileName: "mixkit-retro-game-emergency-alarm-1000.wav"),
        AlarmSound(id: "tick_tock_clock", name: "Tick Tock Clock", fileName: "mixkit-tick-tock-clock-timer-1045.wav"),
        AlarmSound(id: "star_dust_alarm", name: "Star Dust Alarm Clock", fileName: "star-dust-alarm-clock.mp3")
    ]
    
    // MARK: - Computed Properties
    
    var displayText: String {
        if let selected = selectedSound {
            return selected.displayName
        }
        return "Default"
    }
    
    var hasValue: Bool {
        selectedSound != nil
    }
    
    // MARK: - Methods
    
    func selectSound(_ sound: AlarmSound) {
        selectedSound = sound
        stopPreview()
    }
    
    func selectSound(_ soundID: String) {
        if let firstIndex = availableSounds.firstIndex(where: { sound in
            sound.id == soundID
        }) {
            selectedSound = availableSounds[firstIndex]
            stopPreview()
        }
    }
    
    func previewSound(_ fileName: String?) {
        stopPreview()
        
        guard let fileName = fileName else {
            // Play system default alarm sound
            playSystemSound()
            currentlyPlayingSound = nil
            return
        }
        
        // Extract extension from filename
        let components = fileName.components(separatedBy: ".")
        guard components.count >= 2 else {
            print("⚠️ Invalid sound file name format: \(fileName)")
            playSystemSound()
            currentlyPlayingSound = nil
            return
        }
        
        let fileExtension = components.last!
        let fileNameWithoutExtension = components.dropLast().joined(separator: ".")
        
        guard let url = Bundle.main.url(forResource: fileNameWithoutExtension, withExtension: fileExtension) else {
            print("⚠️ Sound file not found: \(fileName)")
            // Fallback to system sound
            playSystemSound()
            currentlyPlayingSound = nil
            return
        }
        
        do {
            // Configure audio session for playback
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            isPlaying = true
            currentlyPlayingSound = fileName
        } catch {
            print("⚠️ Error playing sound: \(error)")
            // Fallback to system sound
            playSystemSound()
            currentlyPlayingSound = nil
        }
    }
    
    func pausePreview() {
        audioPlayer?.pause()
        isPlaying = false
    }
    
    func resumePreview() {
        audioPlayer?.play()
        isPlaying = true
    }
    
    func stopPreview() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentlyPlayingSound = nil
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
