# Alarm Sounds

This directory contains custom alarm sounds for the Ticker app.

## Sound Files

The following sound files should be added to this directory in Core Audio Format (.caf):

1. **gentle-chime.caf** - Soft, pleasant chime sound
2. **radar.caf** - Beeping radar-like alarm sound
3. **digital.caf** - Digital alarm beeps
4. **bell.caf** - Classic bell sound
5. **marimba.caf** - Marimba melody alarm
6. **ascending.caf** - Ascending tone alarm

## Audio Format Requirements

- **Format**: Core Audio Format (.caf)
- **Duration**: 5-30 seconds
- **Sample Rate**: 44.1 kHz or 48 kHz
- **Bit Depth**: 16-bit or 24-bit
- **Channels**: Mono or Stereo

## Converting Audio Files

To convert audio files to .caf format, use the `afconvert` command:

```bash
afconvert -f caff -d LEI16@44100 input.mp3 output.caf
```

## Usage

These sound files are referenced by their filename (without extension) in the app's sound picker. Users can select from these sounds when creating or editing alarms.

The system default alarm sound is always available as a fallback option.
