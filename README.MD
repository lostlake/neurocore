# NeuroCore - Apollo Neuro for Apple Watch

A standalone Apple Watch app that delivers Apollo Neuro-inspired haptic vibration therapy using the watch's Taptic Engine. No extra bands or devices needed.

## What is This?

NeuroCore brings the science-backed vibration patterns of Apollo Neuro directly to your Apple Watch. Instead of wearing two separate bands, use your existing Apple Watch to experience gentle haptic rhythms designed to:

- **Boost Energy** - Wake up and increase alertness
- **Improve Focus** - Enhance concentration for deep work
- **Reduce Stress** - Calm your nervous system
- **Sleep Better** - Gentle patterns to help you fall asleep

## How It Works

The app uses the Apple Watch's Taptic Engine to deliver carefully designed vibration patterns that signal safety to your body through your sense of touch. Based on research into how low-frequency vibrations can influence the autonomic nervous system, these patterns aim to:

1. Activate the parasympathetic nervous system (rest & digest)
2. Improve heart rate variability (HRV)
3. Reduce stress response
4. Enhance energy and focus when needed

## Vibe Modes

### Energize Category
- **Energy** - Invigorating rhythms to boost alertness and wake up your body
- **Social** - Feel engaged and at ease for social situations

### Focus Category
- **Focus** - Enhance concentration and mental clarity for deep work
- **Flow** - Enter a productive flow state with sustained attention

### Relax Category
- **Calm** - Ease into a peaceful state and reduce stress
- **Unwind** - Release tension and transition to relaxation
- **Recover** - Support physical and mental recovery after exertion

### Sleep Category
- **Sleep** - Gentle vibrations to help you fall asleep faster
- **Power Nap** - Quick rest to recharge during the day
- **Deep Rest** - Ultra-gentle patterns for restorative rest

## Features

- **10 Unique Vibe Patterns** - Each with distinct vibration rhythms and intensities
- **Adjustable Intensity** - Fine-tune from 5% to 100% in 5% increments
- **Flexible Duration** - Sessions from 15 minutes to 2 hours
- **Live Intensity Control** - Adjust during active sessions
- **Session History** - Track your wellness journey
- **Weekly Stats** - See total time and session counts
- **Preview Mode** - Try any pattern before starting a full session
- **Background Sessions** - Sessions continue when display sleeps

## Technical Details

### Vibration Patterns

Each mode uses a unique combination of:
- **Waveform Type** - Sine, square, triangle, or pulse waves
- **Base Frequency** - Ranging from 1.5 Hz (Deep Rest) to 12 Hz (Energy)
- **Cycle Duration** - Pattern repeat intervals from 2s to 8s
- **Haptic Events** - Precisely timed sequences of different haptic types

### Haptic Implementation

The app leverages `WKHapticType` variants:
- `.click` - Light taps for subtle patterns
- `.directionUp` - Stronger pulses for emphasis
- `.notification` - Maximum intensity events
- `.start` - Session initiation feedback
- `.success` - Session completion notification

### Pattern Modulation

Vibrations aren't constant - they follow wave patterns:
- **Breathing rhythm** - Intensity rises and falls naturally
- **Wave modulation** - Different waveforms create different sensations
- **Randomized micro-variations** - Prevents habituation

## Requirements

- watchOS 10.0 or later
- Apple Watch Series 4 or later (for best haptic experience)

## Project Structure

```
NeuroCore/
├── NeuroCore.xcodeproj/
└── NeuroCore Watch App/
    ├── NeuroCoreApp.swift          # App entry point
    ├── ContentView.swift           # Main menu with mode selection
    ├── Info.plist                  # App configuration
    ├── Assets.xcassets/            # App icons and colors
    ├── Models/
    │   ├── VibeMode.swift          # Vibe mode definitions
    │   └── VibrationPatterns.swift # Pattern configurations
    ├── Views/
    │   ├── VibeDetailView.swift    # Mode configuration screen
    │   ├── ActiveSessionView.swift # Running session UI
    │   └── SettingsView.swift      # App settings & history
    └── Services/
        ├── HapticEngine.swift      # Core haptic playback engine
        └── SessionManager.swift    # Session state management
```

## Building

1. Open `NeuroCore/NeuroCore.xcodeproj` in Xcode 15+
2. Select your Apple Watch as the target device
3. Build and run

## Usage Tips

- **Start gentle** - Begin with 30-50% intensity and increase as needed
- **Wear it right** - Ensure your watch band is snug for best haptic transmission
- **Be consistent** - Use 3+ hours daily for best results (per Apollo Neuro research)
- **Try different modes** - What works varies by person and situation
- **Layer with activities** - Use Focus during work, Calm during meditation, Sleep at bedtime

## Disclaimer

This app is inspired by Apollo Neuro's approach but is not affiliated with or endorsed by Apollo Neuroscience, Inc. The vibration patterns are original implementations based on publicly available information about haptic wellness technology. Results may vary. This is not a medical device.

## License

MIT License
