# App Store Screenshots Guide

## Required Sizes
- **Apple Watch 45mm**: 396 x 484 pixels
- **Apple Watch 41mm**: 352 x 430 pixels

## Screenshot Strategy (5-8 screenshots recommended)

### Screenshot 1: Hero - Active Session
**Screen**: ActiveSessionView during a Calm session
**Caption**: "Feel the calm"
**Shows**:
- Progress ring with teal color
- Time remaining
- Biometric stress indicator showing "Relaxed"
- Pause/Stop controls

### Screenshot 2: Mode Selection
**Screen**: ContentView main menu
**Caption**: "10 wellness modes"
**Shows**:
- Recommended mode card with time-based suggestion
- Category tabs (Energize, Focus, Relax, Sleep)
- Mode grid with colorful icons

### Screenshot 3: Biometric Adaptive
**Screen**: BiometricDetailView sheet
**Caption**: "Adapts to your body"
**Shows**:
- Heart rate display
- HRV display
- Stress level indicator
- Adaptive intensity explanation

### Screenshot 4: Mode Detail
**Screen**: VibeDetailView for Focus mode
**Caption**: "Customize your session"
**Shows**:
- Intensity slider
- Duration picker
- Start button
- Favorite/Schedule buttons

### Screenshot 5: Smart Recommendations
**Screen**: ContentView showing morning recommendation
**Caption**: "Smart suggestions"
**Shows**:
- "Good morning!" recommendation card
- Energy mode suggested
- Time-based reasoning

### Screenshot 6: Streak & Progress
**Screen**: SettingsView streak section
**Caption**: "Build healthy habits"
**Shows**:
- Current streak with flame icon
- Best streak with trophy
- Weekly session stats

### Screenshot 7: Schedule Sessions
**Screen**: SettingsView scheduled section
**Caption**: "Never miss a session"
**Shows**:
- Scheduled session list
- Time and repeat info
- Enable/disable toggles

### Screenshot 8: Complication
**Screen**: Watch face with NeuroCore complication
**Caption**: "One tap access"
**Shows**:
- Watch face with circular complication
- Streak count visible
- Quick launch capability

---

## Screenshot Text Overlays

For App Store, add text overlays to screenshots:

| Screenshot | Overlay Text |
|------------|--------------|
| 1 | "Soothing vibrations for instant calm" |
| 2 | "Choose your goal" |
| 3 | "Responds to your stress level" |
| 4 | "Personalize intensity & duration" |
| 5 | "Right mode, right time" |
| 6 | "Track your wellness journey" |
| 7 | "Build a daily routine" |
| 8 | "Quick access from any watch face" |

---

## How to Capture Screenshots

### Option 1: Simulator
```bash
# Run Watch simulator
xcrun simctl boot "Apple Watch Series 9 - 45mm"

# Take screenshot
xcrun simctl io booted screenshot screenshot1.png
```

### Option 2: Real Device
1. Open Watch app on iPhone
2. General > Enable Screenshots
3. Press Digital Crown + Side Button simultaneously

### Option 3: SwiftUI Previews
Use Xcode Previews and export via:
- Right-click preview → "Export Image"
- Or use `ImageRenderer` in code

---

## Color Scheme for Marketing

| Element | Color |
|---------|-------|
| Primary | #00D4AA (Teal/Cyan) |
| Secondary | #6366F1 (Indigo) |
| Energize | #F97316 (Orange) |
| Focus | #3B82F6 (Blue) |
| Relax | #22C55E (Green) |
| Sleep | #A855F7 (Purple) |
| Background | #1A1A2E (Dark) |
