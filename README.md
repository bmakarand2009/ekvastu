# VVP - Vastu Virtual Planner

A Flutter mobile application that helps users apply Vastu principles to their living spaces.

## Features

1. **Direction Compass**
   - Real-time directional mapping using device sensors
   - Displays North/East/South/West directions
   - Shows Vastu significance for each direction

2. **Room Check Wizard**
   - Evaluate if rooms are optimally placed according to Vastu principles
   - Support for different room types (Bedroom, Kitchen, Living Room, etc.)
   - Provides room-specific Vastu score

3. **Vastu Recommendations**
   - Personalized remedies for each room based on direction
   - Color recommendations aligned with Vastu principles
   - Actionable suggestions for improvements

4. **Saved Evaluations**
   - Store and review past room evaluations
   - Track overall Vastu score for your home
   - Monitor improvements over time

## Getting Started

### Prerequisites

- Flutter SDK (2.19.0 or higher)
- Android Studio or VS Code with Flutter plugins
- iOS development tools (for iOS deployment)

### Installation

1. Clone the repository
   ```
   git clone https://github.com/yourusername/vvp_app.git
   ```

2. Navigate to the project directory
   ```
   cd vvp_app
   ```

3. Install dependencies
   ```
   flutter pub get
   ```

4. Run the app
   ```
   flutter run
   ```

## Usage Guide

### Direction Compass

1. Open the app and tap on "Direction Compass" from the home screen
2. Hold your device flat and parallel to the ground
3. The compass will show which direction you're facing
4. Tap the info button to see Vastu significance for your current direction

### Room Check Wizard

1. From the home screen, tap on "Room Check Wizard"
2. Select the room type you want to evaluate
3. Either use the device compass or manually select the room's direction
4. Tap "Check Room Compatibility" to get your room's Vastu evaluation
5. Review recommendations and save the results

### Viewing Saved Results

1. From the home screen, tap on "Saved Evaluations"
2. View your overall Vastu score
3. Browse through individual room evaluations
4. Tap on any room to view its detailed evaluation

## Permissions

The app requires the following permissions:
- Location: For compass functionality
- Motion sensors: For device orientation detection

## Dependencies

- `flutter_compass`: ^0.8.0
- `sensors_plus`: ^3.0.2
- `provider`: ^6.0.5
- `shared_preferences`: ^2.2.0
- `google_fonts`: ^5.1.0
- `url_launcher`: ^6.1.12
- `flutter_svg`: ^2.0.7
- `intl`: ^0.18.1

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Inspiration: Traditional Vastu Shastra principles
- Icons: Material Design icons
- Special thanks to the Flutter community for their invaluable resources
